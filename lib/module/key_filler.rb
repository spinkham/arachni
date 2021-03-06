=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni
module Module

#
# KeyFiller class
#
# Included by {Module::Auditor}.<br/>
# Tries to fill in webapp parameters with values of proper type
# based on their name.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.1
#
class KeyFiller
  
    # Hash of regexps for the parameter keys
    # and the values to to fill in
    #
    # @return  [Hash]
    #
    @@regexps = {
        'name'    => 'arachni_name',
        'user'    => 'arachni_user',
        'usr'     => 'arachni_user',
        'pass'    => '5543!%arachni_secret',
        'txt'     => 'arachni_text',
        'num'     => '132',
        'amount'  => '100',
        'mail'    => 'arachni@email.gr',
        'account' => '12',
        'id'      => '1'
    }
        
    #
    # Tries to fill a hash with values of appropriate type<br/>
    # based on the key of the parameter.
    #
    # @param  [Hash]  hash   hash of name=>value pairs
    #
    # @return   [Hash]
    #
    def self.fill( hash )
        
        hash.keys.each{
            |key|
            
            next if hash[key] && !hash[key].empty?
            
            if val = self.match?( key )
                hash[key] = val
            end
            
            # moronic default value...
            # will figure  out ssomething better in the future...
            hash[key] = '1' if( !hash[key] || hash[key].empty? )
        }
        
        return hash
    end
    
    private
    
    def self.match?( str )
      @@regexps.keys.each {
        |key|
        return @@regexps[key] if( str =~ Regexp.new( key, 'i' ) )
        
      }
      return false
    end
    
end

end
end
