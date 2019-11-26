.PHONY: test

test:
	rspec

.PHONY: doc doc/rdoc
doc: doc/rdoc
	
doc/rdoc:
	rm -rf doc/rdoc
	rdoc -o doc/rdoc README.md \
		lib/simple/service.rb \
		lib/simple/service/action.rb \
		lib/simple/service/context.rb \
		lib/simple/service/errors.rb \
		lib/simple/service/version.rb 
