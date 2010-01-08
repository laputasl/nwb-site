#
# Copyright (c) 2007 Todd A. Fisher
#
# Portions Copyright (c) 2008 Shanti A. Braford
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'rubygems'
require 'hpricot'

module ET

  #
  # usage:
  #
  #   # get an existing subscriber
  #   subscriber = Subscriber.load!('user@example.com')
  #   => ET::Subscriber
  #
  #   # subscribe a new user to an existing list
  #   subscriber = Subscriber.add('user@example.com',list)
  #   => ET::Subscriber
  #
  class Subscriber < Client
    attr_accessor :attrs
    attr_reader :email, :status

    def initialize(username,password,options={})
      super
      @attrs = {}
    end

    def load!(email)
      @email = email
      response = send do|io|
        io << render_template('subscriber_retrieve')
      end
      Error.check_response_error(response)
      load_response(response.read_body)
    end

    def load_response(body)
      doc = Hpricot.XML(body)
      subscriber = doc.at(:subscriber)
      # load elements into the attrs hash
      @attrs = {}
      subscriber.each_child do|attr_element|
        if attr_element.elem?
          name = attr_element.name.gsub(/__/,' ')
          value = attr_element.inner_html
          @attrs[name] = value
          if name == 'Email Address'
            @email = value
          elsif name == 'Status'
            @status = value
          end
        end
      end
    end
    private :load_response

    # desc:
    #   add this user as a new subscriber to the list, with a set of attributes
    # params:
    #   listid: id of the e-mail list to subscribe this user to
    #   email: E-mail address of subscriber
    def add( email, listid, attributes ={} )
      @email = email
      @subscriber_listid = listid
      @attributes = attributes
      response = send do|io|
        io << render_template('subscriber_add')
      end
      Error.check_response_error(response)
      doc = Hpricot.XML(response.read_body)
      doc.at("subscriber_description").inner_html.to_i
    end

    # desc:
    #   update this a subscriber
    # params:
    #   listid: id of the e-mail list to subscribe this user to
    #   email: E-mail address of subscriber
    #   subscriberid: id for the subscriber to update
    def update(subscriberid, email, listid, attributes ={} )
      @email = email
      @listid = listid
      @subscriberid = subscriberid
      @attributes = attributes
      response = send do|io|
        io << render_template('subscriber_update')
      end
      Error.check_response_error(response)
      doc = Hpricot.XML(response.read_body)
      doc.at("subscriber_description").inner_html.to_i
    end

    # desc:
    #   delete this user as a new subscriber to the list, or completely from ET
    # params:
    #   listid: id of the e-mail list to unsubscribe this user from
    #   email: E-mail address of subscriber
    #   subscriberid: id for the subscriber to delete COMPLETELY
    def delete(subscriberid, email, listid, attributes ={} )
      @email = email
      @subscriber_listid = listid
      @subscriberid = subscriberid

      puts render_template('subscriber_delete')
      response = send do|io|
        io << render_template('subscriber_delete')
      end
      Error.check_response_error(response)
      doc = Hpricot.XML(response.read_body)
      doc.at("subscriber_info").inner_html
    end


  end
end
