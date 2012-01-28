
require "savon/core_ext/string"
require "nori"
require "akami"

module Savon

  # = Savon::WSA
  #
  # Provides WS-Addressing.
  class WSA

    # Namespace for WS Addressing.
    WSANamespace = "http://www.w3.org/2005/08/addressing"

    # Namespace for WS Security Utility.// dupe from WSSE...
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # Returns a value from the WSA Hash.
    def [](key)
      hash[key]
    end

    # Sets a value on the WSA Hash.
    def []=(key, value)
      hash[key] = value
    end

    attr_accessor :action, :message_id, :reply_to, :to

    ## The WSA specification dictates these rules, see §3.1 at http://www.w3.org/Submission/ws-addressing/
    def ws_addressing?
      ret_val = false
      if (action && to)
        ret_val = true
        if (reply_to && !message_id)
          ret_val = false
        end
      end
      ret_val
    end

    # Returns the XML for a WSA header.
    def to_xml
      @other_xml ||= Gyoku.xml(hash)

      xml = ""

      if ws_addressing?
        xml += Gyoku.xml wsa_element("Action", action).merge!(hash)
        xml += Gyoku.xml wsa_element("To", to).merge!(hash)
        if reply_to
          xml += Gyoku.xml wsa_element("ReplyTo", reply_to, "Address").merge!(hash)
          xml += Gyoku.xml wsa_element("MessageID", message_id).merge!(hash) # must be present when reply_to is present, see the WSA spec
        elsif message_id
          xml += Gyoku.xml wsa_element("MessageID", message_id).merge!(hash)
        end
      end

      xml + @other_xml
    end

  private

    def wsa_element(tag, value, nested_tag=nil, id=nil)
      id = "#{tag}" if id.nil?
      value = {"wsa:"+nested_tag => value } unless nested_tag.nil?
      {
        "wsa:#{tag}" => value,
        :attributes! => { "wsa:#{tag}" => { "wsu:Id" => id, "xmlns:wsa" => WSANamespace , "xmlns:wsu" => WSUNamespace } }
      }
    end

    # Returns a new number with every call.
    def count
      @count ||= 0
      @count += 1
    end

    #TODO - are these needed?

    # Returns a memoized and autovivificating Hash.
    def hash
      @hash ||= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    end

  end
end
