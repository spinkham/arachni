=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/element_db'
require Arachni::Options.instance.dir['lib'] + 'module/output'

module Arachni
module Module

#
# Trainer class
#
# Analyzes all HTTP responses looking for new auditable elements.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
class Trainer
    
    include Output
    include ElementDB
    include Singleton

    attr_writer   :page
    attr_accessor :http
    attr_accessor :analyzer

    def initialize
      @opts     = Options.instance
      @analyzer = Analyzer.new( @opts )
      @updated  = false
    end

    #
    # Passes the reponse to {#analyze} for analysis
    #
    # @param  [Typhoeus::Response]  res
    # @param  [Bool]  redir  was the response forcing a redirection?
    #
    def add_response( res, redir = false )

        begin
            url = res.effective_url
            url = URI( to_absolute( url ) )
            
            return if !follow?(  url )
            return if ( redir && !follow?(  url ) )
          
            analyze( [ res, redir ] )
            
        rescue
            print_error( "Invalid URL, probably broken redirection. Ignoring..." )
            # raise
        end

    end
    
    #
    # Decodes URLs to reverse multiple encodes and removes NULL characters
    #
    def url_sanitize( url )
        
        while( url =~ /%/ )
            url = ( URI.decode( url ).to_s.unpack( 'A*' )[0] )
        end 
        
        return URI.encode( url )
    end
    
    def follow?( url )
        @analyzer.url = @page.url
        
        return false if !@analyzer.in_domain?( url )
        return false if @analyzer.exclude?( url ) 
        return false if !@analyzer.include?( url )
        return true
    end
    
    #
    # Returns an updated {Page} object or nil if there waere no updates
    #
    # @return  [Page]
    #
    def page
        if( @updated  )
              @updated = false
              # page = @page.dup
              # @page = nil
              return  @page
          else
              return nil
        end
    end

    
    #
    # Analyzes a response looking for new links, forms and cookies.
    #
    # @param   [Typhoeus::Response, Bool]  res
    #
    def analyze( res )
        
        print_debug( 'Started for response with request ID: #' + 
          res[0].request.id.to_s )
        

        cookies, cookie_cnt = train_cookies( res[0] )
        if ( cookie_cnt > 0 )
            @page.elements['cookies'] = cookies.flatten
            @updated = true
            
            print_debug( 'Found ' + cookie_cnt.to_s + ' new cookies.' )
        end
        
        # if the response body is the same as the page body and
        # no new cookies have appeared there's no reason to analyze the page
        if( res[0].body == @page.html && !@updated )
            print_debug( 'Page hasn\'t changed, skipping...' )
            return
        end
        
        forms, form_cnt = train_forms( res[0] )
        links, link_cnt = train_links( res[0], res[1] )
        
        if ( form_cnt > 0 )
            @page.elements['forms'] = forms.flatten
            @updated = true
            
            print_debug( 'Found ' + form_cnt.to_s + ' new forms.' )
        end
        
        if ( link_cnt > 0 )
            @page.elements['links'] = links.flatten
            @updated = true
            
            print_debug( 'Found ' + link_cnt.to_s + ' new links.' )
        end
        
        if( @updated )
          
            @page.html = res[0].body.dup

            begin
                url           = res[0].request.url
                # prepare the page url
                @analyzer.url = to_absolute( url )
            rescue
                print_error( "Invalid URL, probably broken redirection. Ignoring..." )
                # raise
            end

            @page.request_headers = res[0].request.headers
            @page.query_vars = @analyzer.get_link_vars( @page.url ).dup

        end

        print_debug( 'Training complete.' )
    end
    
    private
    
    def to_absolute( url )
        effective_url = url_sanitize( url )
        @page.url     = url_sanitize( @page.url )
        
        # prepare the page url
        return (URI.parse( @page.url ).merge( URI( effective_url ) )).to_s.dup    
    end
    
    def train_forms( res )
        return [], 0 if !@opts.audit_forms
        
        @analyzer.url = res.effective_url.clone
        forms = @analyzer.get_forms( res.body ).clone
        
        return update_forms( forms )
    end
    
    def train_links( res, redir = false )
        return [], 0  if !@opts.audit_links
        
        @analyzer.url = res.effective_url.clone

        links   = @analyzer.get_links( res.body ).clone
        
        if( redir )
            links.push( {
                'href' => @analyzer.url,
                'vars' => @analyzer.get_link_vars( @analyzer.url )
            } )
            
        end
        
        return update_links( links )
    end
    
    def train_cookies( res )
        cookies = @analyzer.get_cookies( res.headers_hash['Set-Cookie'].to_s ).clone        
        return update_cookies( cookies )
    end

    
    def self.info
      { :name  => 'Trainer' }
    end
    
end
end
end
