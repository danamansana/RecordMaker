# RecordMaker
RecordMaker is an application that allows users to integrate models with a database. RecordMaker provides users with built
in methods that generate new instances from data in a database, and allows the user to query a database and receive objects
of the appropriate type instead of rows from the database. It supplies built in association methods for models, permittting
the user to grab related objects.

# Implementation

RecordMaker uses SQLite3 to provide a database on top of which RecordMaker objects are built. It automates the production of SQL
queries for standard requests, including finding objects by id, or finding associated objects from a given starting point.
The most interesting feature is that these associations can be built on top of each other: A human can have cats, which can have toys,
etc, and the human can therefore have toys. This feature avoid N+1 queries by using join tables. In order to ensure that associations
can be built on top of each other without limit, RecordMaker recursively generates SQL query text, only generating an actualy query 
when the final query is ready to be made.
