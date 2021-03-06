=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

module Modules
module Audit

#
# Blind SQL injection audit module
#
# It uses reverse-diff analysis of HTML code in order to determine successful
# blind SQL injections.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.2
#
# @see http://cwe.mitre.org/data/definitions/89.html
# @see http://capec.mitre.org/data/definitions/7.html
# @see http://www.owasp.org/index.php/Blind_SQL_Injection
#
class BlindSQLInjection < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # initialize the results array
        @results = []
    end

    def prepare( )
        
        # possible quote characters used in SQL statements
        @__quotes = [
            '\'',
            '"',
            ''
        ]

        # this will cause a silent error if there's a blind SQL injection
        @__bad_chars =[
           '\'"`',
           # we need 2 requests thus we change the second one a little bit to
           # fool the Auditor's redundancy filter
           '\'"``' 
         ]

        # %q% will be replaced by a character in @__quotes
        @__injection = '%q% and %q%1'
        
        @__opts = {
            :format      => [ Format::APPEND ],
            # we need to do our own redundancy checks
            :redundant   => true,
            # sadly, we need to disable asynchronous requests
            # otherwise the code would get *really* ugly
            :async       => false
        }
        
        # used for redundancy checks 
        @@__audited ||= []
        
    end
    
    def run( )
        
        return if( __audited? )
        
        if( @page.query_vars.empty? )
            print_status( 'Nothing to audit on current page, skipping...' )
            return
        end
        
        # let's get a fresh rendering of the page to assist us with
        # irrelevant dynamic content elimination (banners, ads, etc...)
        opts = {}
        opts[:params] = @page.query_vars
        opts[:async]  = false
        res  = @http.get( @page.url, opts ).response

        # eliminate dynamic content that's context-irrelevant
        # ie. changing with every refresh
        @__content = Module::Utilities.rdiff( @page.html, res.body )
        
        # force the webapp to return an error page
        __prep_bad_response( )
        
        # start injecting 'nice' SQL queries 
        __audit( )
        
        # analyze the HTML code of the responses in order to determine
        # which injections were succesfull
        __analyze( )
        
        # register our results with the framework
        register_results( @results )
    end
    
    def clean_up
        @@__audited << __audit_id( )
        @@__audited.uniq!
    end
    
    def __audit_id
        "#{URI( @page.url).path}::#{@page.query_vars.keys}"
    end
    
    def __audited?
        @@__audited.include?( __audit_id( ) )
    end
    
    # Audits page with 'bad' SQL characters and gathers error pages
    def __prep_bad_response( )
        
        @__html_bad ||= {}

        @__bad_chars.each {
            |str|
            
            audit( str, @__opts ) {
                |res, var, opts|
                
                next if !res || !res.body
                @__html_bad[var] ||= res.body.clone
                
                # remove context-irrelevant dynamic content like banners and such
                # from the error page
                @__html_bad[var] = Module::Utilities.rdiff( @__html_bad[var], res.body.clone )
            }
        }
        
        return @__html_bad
    end
    
    # Injects SQL code that doesn't affect the flow of execution nor presentation
    def __audit( )
        
        @__html_good ||= {}
        
        @__quotes.each {
            |quote|
            
            # prepare the statement with combinations of quote characters
            str = @__injection.gsub( '%q%', quote )
            
            # inject the statement
            audit( str, @__opts ) {
                |res, var, opts|

                @__html_good[var] ||= []

                # save the response for later analysis
                @__html_good[var] << {
                    'str'  => str,
                    'res'  => res,
                    'opts' => opts
                }
                
            }
        }

    end
    
    # Goes through the responses induced by {#__audit} and {#__check} their code
    def __analyze( )
        @__html_good.keys.each {
            |key|
            @__html_good[key].each {
                |res|
                __check( res['str'], res['res'], key, res['opts'] )
            }
        }
    end
    
    #
    # Compares HTML responses in order to identify successful blind sql injections
    #
    # @param  [String]  str  the string that unveiled the vulnerability
    # @param  [Typhoeus::Response]
    # @param  [String]  var   the vulnerable variable
    # @param  [Hash]    opts  the options passed to the {#audit} block
    #
    def __check( str, res, var, opts )
      
        # if one of the injections gives the same results as the
        # original page then a blind SQL injection exists
        check = Module::Utilities.rdiff( res.body, @page.html )

        if( check == @__content && @__html_bad[var] != check &&
            !@http.custom_404?( res.body ) )
            __log_results( opts, var, res, str )
        end

    end
    
    def self.info
        {
            :name           => 'BlindSQLInjection',
            :description    => %q{Blind SQL injection audit module.},
            :elements       => [
                Vulnerability::Element::LINK
            ],
            :author          => 'zapotek',
            :version         => '0.2',
            :references      => {
                'OWASP'      => 'http://www.owasp.org/index.php/Blind_SQL_Injection',
                'MITRE - CAPEC' => 'http://capec.mitre.org/data/definitions/7.html'
            },
            :targets        => { 'Generic' => 'all' },
                
            :vulnerability   => {
                :name        => %q{Blind SQL Injection},
                :description => %q{SQL code can be injected into the web application.},
                :cwe         => '89',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '9.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end
    
    private
    
    def __log_results( opts, var, res, str )
      
        url = res.effective_url
        @results << Vulnerability.new( {
                :var          => var,
                :url          => url,
                :injected     => str,
                :id           => str,
                :regexp       => 'n/a',
                :regexp_match => 'n/a',
                :elem         => opts[:element],
                :response     => res.body,
                :headers      => {
                    :request    => res.request.headers,
                    :response   => res.headers,    
                }
            }.merge( self.class.info )
        )

        print_ok( "In #{opts[:element]} var '#{var}' ( #{url} )" )
            
        # register our results with the system
        register_results( @results )
    end

end
end
end
end
