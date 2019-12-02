# simple-service – at your service!

The `simple-service` ruby gem helps you turn your ruby source code into *"services".* A service is a module which provides interfaces to one or more methods (*"actions"*) that implement business logic.

While one could, of course, call any such method any way one wants, this gem lets you

- discover available services (their names, their parameters (name, type, default values), comments - see `Simple::Service.actions`;
- an interface to "run" (or "execute") a service, with separation from any other parallel runs - see `Simple::Service.invoke` and `Simple::Service.invoke2`;
- a semi-constant "*environment*" for the duration of an execution;
- ![TODO](https://badgen.net/badge/TODO/high?color=red) a normalized interface to check whether or not a specific service is allowed to run based on the current context.

These features allow *simple-service* to serve as a building block for other tools. It is currently in used in:

- *simple-httpd*: a simple web server
- *simple-cli*: the best way to build a ruby CLI.

## Example

### Defining a service

A service module can define one or more services. The following example defines a single service:

    # A service which constructs universes with different physics.
    module GodMode
      include Simple::Service

      # Build a universe.
      #
      # This comment will become part of the full description of the
      # "build_universe" service
      def build_universe(name, c: , pi: 3.14, e: 2.781)
        # at this point I realize that *I* am not God.

        42 # Best try approach
      end
    end

### Running a service

To run the service one uses one of two different methods. If you have an **anonymous array** of arguments - think command line interface - you would call it like this:

    Simple::Service.invoke GodMode, :build_universe, 
                           "My Universe", 
                           c: 3e8

If the calling site, however, has **named arguments** (in a Hash), one would invoke a service using `invoke2`. This is used for HTTPD integration (with `simple-httpd`.)

      args = { name:  "My Universe", c: 299792458}
      Simple::Service.invoke2 GodMode, 
                              :build_universe, 
                              args: args

Note that you must set a context during the execution; this is done by `with_context`. A  `nil` context is a valid value which describes an empty context.

A full example could therefore look like:

    Simple::Service.with_context(nil) do
        args = { name:  "My Universe", c: 299792458}
        Simple::Service.invoke2 GodMode, 
                                :build_universe,
                                args: args
    end

## History

Historically, the `simple-cli` gem implemented an easy way to build a CLI application, and therefore needed a way to reflect on existing code to determine which methods to call, which arguments they support etc. Also, the `postjob` job queue calls a specific method based on its name and an arguments Array or Hash, which is being read from a database. Finally, when I tried to extent `postjob` with a HTTP interface I discovered that a similar feature would again be extremely useful.

I therefore extracted these features into a standalone gem.
