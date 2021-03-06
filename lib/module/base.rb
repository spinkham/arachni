=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require Arachni::Options.instance.dir['lib'] + 'module/output'
require Arachni::Options.instance.dir['lib'] + 'module/utilities'
require Arachni::Options.instance.dir['lib'] + 'module/trainer'
require Arachni::Options.instance.dir['lib'] + 'module/auditor'

module Arachni
module Module


#
# Arachni's base module class<br/>
# To be extended by Arachni::Modules.
#    
# Defines basic structure and provides utilities to modules.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
# @abstract
#
class Base

    # get output module
    include Output

    include Auditor
    
    #
    # Arachni::HTTP instance for the modules
    #
    # @return [Arachni::Module::HTTP]
    #
    attr_reader :http

    #
    # Arachni::Page instance
    #
    # @return [Page]
    #
    attr_reader :page
    
    #
    # Initializes the module attributes, HTTP client and {Trainer}
    #
    # @see Trainer
    # @see HTTP
    #
    # @param  [Page]  page
    #
    def initialize( page )
        
        @page  = page
        @http  = Arachni::Module::HTTP.instance
        Arachni::Module::Trainer.instance.page = @page.dup
        
        # initialize the HTTP cookiejar with the user supplied one
        if( @page.cookiejar )
            @http.set_cookies( @page.cookiejar )
        end
        
        #
        # This is slightly tricky...
        #
        # Each loaded module is instantiated for each page,
        # however modules share the elements of each page and access them
        # via the ElementsDB.
        #
        # Since the ElementDB is dynamically updated by the Trainer
        # during the audit, is should only be initialized *once* 
        # for each page and not overwritten every single time a module is instantiated.
        #
        @@last_url ||= ''
        if( @@last_url != @page.url )
            Trainer.instance.page = @page.dup
            Trainer.instance.init_seed( Arachni::Module::Utilities.seed )
            Trainer.instance.init_forms( get_forms )
            Trainer.instance.init_links( get_links )
            Trainer.instance.init_cookies( get_cookies )
            
            @@last_url = @page.url
        end
        
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # It provides you with a way to setup your module's data and methods.
    #
    def prepare( )
    end

    #
    # ABSTRACT - REQUIRED
    #
    # This is used to deliver the module's payload whatever it may be.
    #
    def run( )
    end

    #
    # ABSTRACT - OPTIONAL
    #
    # This is called after run() has finished executing,
    #
    def clean_up( )
    end
    
    #
    # ABSTRACT - REQUIRED
    #
    # Provides information about the module.
    # Don't take this lightly and don't ommit any of the info.
    #
    def self.info
        {
            :name           => 'Base module abstract class',
            :description    => %q{Provides an abstract class the modules should implement.},
            #
            # Arachni needs to know what elements the module plans to audit
            # before invoking it.
            # If a page doesn't have any of those elements
            # there's no point in instantiating the module.
            #
            # If you want the module to run no-matter what leave the array
            # empty.
            #
            # 'Elements'       => [
            #     Vulnerability::Element::FORM,
            #     Vulnerability::Element::LINK,
            #     Vulnerability::Element::COOKIE,
            #     Vulnerability::Element::HEADER
            # ],
            :elements       => [],
            :author         => 'zapotek',
            :version        => '0.1',
            :references     => {
            },
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :description => %q{},
                :cwe         => '',
                #
                # Severity can be:
                #
                # Vulnerability::Severity::HIGH
                # Vulnerability::Severity::MEDIUM
                # Vulnerability::Severity::LOW
                # Vulnerability::Severity::INFORMATIONAL
                #
                :severity    => '',
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }
        }
    end
    
    #
    # ABSTRACT - OPTIONAL
    #
    # In case you depend on other modules you can return an array
    # of their names (not their class names, the module names as they
    # appear by the "-l" CLI argument) and they will be loaded for you.
    #
    # This is also great for creating audit/discovery/whatever profiles.
    #
    def self.deps
        # example:
        # ['eval', 'sqli']
        []
    end
    
    #
    # Returns extended form information from {Page#elements}
    #
    # @see Page#get_forms
    #
    # @return    [Aray]    forms with attributes, values, etc
    #
    def get_forms
        @page.get_forms( )
    end
    
    #
    #
    # Returns extended link information from {Page#elements}
    #
    # @see Page#get_links
    #
    # @return    [Aray]    link with attributes, variables, etc
    #
    def get_links
        @page.get_links( )
    end

    #
    # Returns an array of forms from {#get_forms} with its attributes and<br/>
    # its auditable inputs as a name=>value hash
    #
    # @return    [Array]
    #
    def get_forms_simple( )
        forms = []
        get_forms( ).each_with_index {
            |form|
            forms << get_form_simple( form )
        }
        forms
    end

    #
    # Returns the form with its attributes and auditable inputs as a name=>value hash
    #
    # @return    [Array]
    #
    def get_form_simple( form )
        
        
        return if !form || !form['auditable']
        
        new_form = Hash.new
        new_form['attrs'] = form['attrs']
        new_form['auditable'] = {}
        form['auditable'].each {
            |item|
            if( !item['name'] ) then next end
            new_form['auditable'][item['name']] = item['value']
        }
        return new_form
    end
    
    #
    # Returns links from {#get_links} as a name=>value hash with href as key
    #
    # @return    [Hash]
    #
    def get_links_simple
        links = Hash.new
        get_links( ).each_with_index {
            |link, i|
            
            if( !link['vars'] || link['vars'].size == 0 ) then next end
                
            links[link['href']] = Hash.new
            link['vars'].each_pair {
                |name, value|
                
                if( !name || !link['href'] ) then next end
                    
                links[link['href']][name] = value
            }
            
        }
        links
    end
    
    #
    # Returns extended cookie information from {Page#elements}
    #
    # @see Page#get_cookies
    #
    # @return    [Array]    the cookie attributes, values, etc
    #
    def get_cookies
        @page.get_cookies( )
    end

    #
    # Returns cookies from {#get_cookies} as a name=>value hash
    #
    # @return    [Hash]    the cookie attributes, values, etc
    #
    def get_cookies_simple( incookies = nil )
        cookies = Hash.new( )
        
        incookies = get_cookies( ) if !incookies
        
        incookies.each {
            |cookie|
            cookies[cookie['name']] = cookie['value']
        }
        
        return cookies if !@page.cookiejar
        @page.cookiejar.merge( cookies )
    end
    
    #
    # Returns a cookie from {#get_cookies} as a name=>value hash
    #
    # @param    [Hash]     cookie
    #
    # @return    [Hash]     simple cookie
    #
    def get_cookie_simple( cookie )
        return { cookie['name'] => cookie['value'] }
    end

    
    #
    # Returns a hash of auditable request headers.
    #
    # @see Page#request_headers
    #
    # @return    [Hash]
    #
    def get_headers( )
       return @page.request_headers 
    end
    
    #
    # Gets module data files from 'modules/[modtype]/[modname]/[filename]'
    #
    # @param    [String]    filename filename, without the path    
    # @param    [Block]     the block to be passed each line as it's read
    #
    def get_data_file( filename, &block )
        
        # the path of the module that called us
        mod_path = block.source_location[0]
        
        # the name of the module that called us
        mod_name = File.basename( mod_path, ".rb")
        
        # the path to the module's data file directory
        path    = File.expand_path( File.dirname( mod_path ) ) +
            '/' + mod_name + '/'
                
        file = File.open( path + '/' + filename ).each {
            |line|
            yield line.strip
        }
        
        file.close
             
    end
    
end
end
end
