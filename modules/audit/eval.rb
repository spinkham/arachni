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
# eval() audit module.
#
# It audits links, forms and cookies for code injection.
#
# It's designed to work with PHP, Perl, Python, Java, ASP and Ruby
# but still needs some more testing.
#
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
# @see http://cwe.mitre.org/data/definitions/94.html
# @see http://php.net/manual/en/function.eval.php
# @see http://perldoc.perl.org/functions/eval.html
# @see http://docs.python.org/py3k/library/functions.html#eval
# @see http://www.aspdev.org/asp/asp-eval-execute/
# @see http://en.wikipedia.org/wiki/Eval#Ruby
#
class Eval < Arachni::Module::Base

    # register us with the system
    include Arachni::Module::Registrar

    def initialize( page )
        super( page )

        # code to inject
        @__injection_strs = []
        
        # digits from a sha1 hash
        # the codes in @__injection_strs will tell the web app
        # to sum them and echo the result
        @__rand1 = '287630581954'
        @__rand2 = '4196403186331128'
        
        # our results array
        @results = []
    end

    def prepare( )
        
        @__opts = {}
        
        # the sum of the 2 numbers as a string
        @__opts[:match]   =  ( @__rand1.to_i + @__rand2.to_i ).to_s
        @__opts[:regexp]  = Regexp.new( @__opts[:match] )

        
        # code to be injected to the webapp
        @__injection_strs = [
            "echo " + @__rand1 + "+" + @__rand2 + ";", # PHP
            "print " + @__rand1 + "+" + @__rand2 + ";", # Perl
            "print " + @__rand1 + " + " + @__rand2, # Python
            "Response.Write\x28" +  @__rand1  + '+' + @__rand2 + "\x29", # ASP
            "puts " + @__rand1 + " + " + @__rand2 # Ruby
        ]
        
        tmp = []
        @__injection_strs.each {
            |str|
            tmp << '; ' + str
        }
        @__injection_strs |= tmp
        
    end
    
    def run( )
        
        # iterate through the injection codes
        @__injection_strs.each {
            |str|
            audit( str, @__opts )            
        }
        
    end

    
    def self.info
        {
            :name           => 'Eval',
            :description    => %q{eval() recon module. Tries to inject code
                into the web application.},
            :elements       => [
                Vulnerability::Element::FORM,
                Vulnerability::Element::LINK,
                Vulnerability::Element::COOKIE
            ],
            :author         => 'zapotek',
            :version        => '0.1.1',
            :references     => {
                'PHP'    => 'http://php.net/manual/en/function.eval.php',
                'Perl'   => 'http://perldoc.perl.org/functions/eval.html',
                'Python' => 'http://docs.python.org/py3k/library/functions.html#eval',
                'ASP'    => 'http://www.aspdev.org/asp/asp-eval-execute/',
                'Ruby'   => 'http://en.wikipedia.org/wiki/Eval#Ruby'
             },
            :targets        => { 'Generic' => 'all' },
                
            :vulnerability   => {
                :name        => %q{Code injection},
                :description => %q{Code can be injected into the web application.},
                :cwe         => '94',
                :severity    => Vulnerability::Severity::HIGH,
                :cvssv2       => '7.5',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

end
end
end
end
