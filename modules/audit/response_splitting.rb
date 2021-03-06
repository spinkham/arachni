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
# HTTP Response Splitting audit module.
#
# It audits links, forms and cookies.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.3
#
# @see http://cwe.mitre.org/data/definitions/20.html    
# @see http://www.owasp.org/index.php/HTTP_Response_Splitting
# @see http://www.securiteam.com/securityreviews/5WP0E2KFGK.html    
#
class ResponseSplitting < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # initialize the header
        @__header = ''
        
        # initialize the array that will hold the results
        @results = []
    end

    def prepare( )
        
        # the header to inject...
        # what we will check for in the response header
        # is the existence of the "x-crlf-safe" field.
        # if we find it it means that the attack was succesful
        # thus site is vulnerable.
        @__header = "\r\nX-CRLF-Safe: no"
    end
    
    def run( )
        
        # try to inject the headers into all vectors
        # and pass a block that will check for a positive result
        audit( @__header ) {
            |res, var, opts|
            __log_results( opts, var, res )
        }
    end

    
    def self.info
        {
            :name           => 'ResponseSplitting',
            :description    => %q{Response Splitting recon module.
                Tries to inject some data into the webapp and figure out
                if any of them end up in the response header. 
            },
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.3',
            :references     => {
                 'SecuriTeam'    => 'http://www.securiteam.com/securityreviews/5WP0E2KFGK.html',
                 'OWASP'         => 'http://www.owasp.org/index.php/HTTP_Response_Splitting'
            },
            :targets        => { 'Generic' => 'all' },
                
            :vulnerability   => {
                :name        => %q{Response splitting},
                :description => %q{The web application includes user input
                     in the response HTTP header.},
                :cwe         => '20',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2       => '5.0',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end
    
    private
    
    def __log_results( opts, var, res )
        if res.headers_hash['X-CRLF-Safe']
          
            url = res.effective_url
            @results << Vulnerability.new( {
                    :var          => var,
                    :url          => url,
                    :injected     => URI.encode( @__header ),
                    :id           => 'x-crlf-safe',
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
end
