# Open Payments Initiative Protocol Library

manage communications between a POS system and a payment terminal
using the OPI protocol.


29/06/2023

## Physical Layer

the communication proceeds via two TCP sockets.


## Install

gem install blix-opi

require 'blix/opi'

## Use

register a handler to handle any device requests from the terminal.

    class MyPrinterHandler < OPI::Handler

      def output(info)
        send_to_printer info['lines'].map{|l| l['text']}.join("\n")
        OPI::Result::Success
      end

    end

configure the interface to the terminal and create a connection object

    options = {
       :logger            # a logger object
       :application_id    # the name of the application for log on terminal
       :workstation_id    # the name of the workstation for log on terminal
       :local_port        # port to listen on
       :remote_host       # terminal ip
       :remote_port       # terminal port
       :timeout_0         # timeout between a connect and message
       :timeout_1         # timeout between request and response
       :timeout_2         # timeout between any messages with terminal
    }


    term = OPI::Terminal.new( options )
    term.register_device OPI::Device::Printer, MyPrinterHandler.new


  listen for device requests

    Thread.new{ term.listen() }

  now perform your requests..

    term.login    # returns true/false

    term.card_payment(22.5, '123BCX')

    term.logoff

# Methods

    * login
    * logoff
    * card_payment(amount, transaction_id)
