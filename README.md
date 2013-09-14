Binary stream tools for Objective C
===================================

Utility classes for reading from and writing to binary NSStreams. Nothing fancy, but hopefully will save time and bugs. Inspired by C#'s BinaryReader and BinaryWriter.

Features
--------

* Works with any old NSStream.
* Works with both big and little endianness.
* Has a test suite of sorts.

Known issues
------------

* Compilation on x64 works, but emits formatting warnings and failed tests due to type mismatches (no logic errors AFAIK).
* Error handling may be cumbersome in some situations.

License
=======

Public domain.
