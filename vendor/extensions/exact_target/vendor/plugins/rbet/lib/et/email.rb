#
# Copyright (c) 2010 Brian D. Quinn
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
  # Email
  # usage:
  #
  #
  #   # retrieve all email definitions
  #   all_email = Email.all()
  #   => Hash
  #
  #   # retrieve email defintion by name
  #   email = Email.retrieve_by_name('My Super Email')
  #   => Hash
  #

  #
  class Email < Client
    def initialize(username,password,options={})
      super
    end

    # desc:
    #   returns hash of all emails definitions
    # params:
    #   none
    def all
      retrieve(nil)
    end

    # desc:
    #   returns hash of email defintion
    # params:
    #   emailname = name of email
    def retrieve_by_name(emailname)
      retrieve(emailname)
    end

    private
    def retrieve(emailname)
      @emailname = emailname
      response = send do|io|
        io << render_template('email_retrieve')
      end
      Error.check_response_error(response)
      h = Hash.from_xml(response.read_body)
      h["exacttarget"]["system"]["email"]["emaillist"]
    end

  end
end