# Solga-Experiments

Investigating what it is like to build a simple API with Solga

Findings:

* No Swagger instances for self describing swagger info in a route
* No easy way to encode a status
	- Created a FixedStatus newtype to alter status of response
* No easy way to build a 404 handler
	- Worked around this by creating a few instances
* Couldn't compile solga against recent version of GHC
	- Bug is quite old just needs a type equality constraint
	- [Example of fix](https://github.com/FintanH/solga/blob/build_error/solga/src/Solga.hs#L286)
	- [Bug raised](https://github.com/chpatrick/solga/issues/9)
* Can't return generic JSON values... No ToSchema instance
	- Worked around by faking as text
