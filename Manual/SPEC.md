css: man.css

# Specification for Dr2

Dr2 (Devyn's RPC 2) is language independent. Here is the specification
for the protocol:

## Data Format

Dr2's data format is very bEncode (from BitTorrent)-like.

These characters should be ignored if not expected:

    0x09    CHARACTER TABULATION
    0x0A    LINE FEED (LF)
    0x0D    CARRIAGE RETURN (CR)
    0x20    SPACE

`.` closes a structure, similar to `e` in bEncode.

### Integer

`i` followed by hexadecimal `[0-9A-Fa-f]` number, ending with '`.`'.

    i33.
    => 51

### List

`l`  followed by  items one  after  another, ending  with '`.`'.   Not
necessarily all of the same type.

    l 3:foo i2. .
    => ["foo", 2]

### Dictionary

`d` followed  by items,  like a  list, but in  key, value,  key, value
order.   The dictionary  is not  necessarily in  any  particular order
(unordered map).  The keys and  values may be  of any type.  Ends with
'`.`'.

    d s3:foo i2. s5:hello s5:world iFF. l i1. i2. i3. . .
    => {hello: "world", foo: 2, 255: [1, 2, 3]}

### Null

`n` is null. It may appear as any object.

    l i2. n i2. .
    => [2, null, 2]

### String

`s` followed by the length in hexadecimal `[0-9A-Fa-f]`, followed by a
colon (`:`), followed by the content of the string. Example:

    s1b:hello world, this is a test
    => "hello world, this is a test"

### Error

`e`, then error id (string), then additional information (arb.)

    e s9:NameError d s7:message s24:undefined local variable .
    => Error{ id: "NameError",
              info: {message: "undefined local variable"} }

### Messages

List syntax,  first element is message id  (arbitrary object, uniquely
identifies  the  response)  second  element  is  treated  as  receiver
(arbitrary object, root is `n`), third is node name (string), and the
rest are the arguments (rev. order like lists). Ends with '`.`'.

    m i10000. n s8:math/add i2. i2. .
    => Message{ id: 65536, to: nil, node: "math/add", args: [2, 2] }

## Response

`r`, followed by the id  corresponding to the message, followed by the
return value.

    r i10000e i4.
    => Response{ id: 65536, value: 4 }

### Pointer

Sometimes it is desirable to send  an object which must be accessed on
the server. The  pointer type `p` allows you to send  a pointer to the
client, which  can then  give you  that pointer as  the receiver  of a
message and  thereby call  methods on that  object. The syntax  is `p`
followed by an arbitrary identifier object.

    p iFF.
    => Pointer 255

One could then access this pointer by sending messages to it:

    m i0. iFF. s7:inspect .
    => Message{ id: 0, to: 255, node: "inspect", args: [] }
    => pseudo : get(0xFF).inspect

Note the  `iFF.` as the second  message parameter. This  object is the
same as the one the pointer was wrapping in the earlier example.

## Protocol

Client  sends messages while  server sends  responses.  Both  may send
toplevel errors, which  may be handled depending on  the service. Only
one response per  message sent. Message and response  are linked by an
identifier, which is an arbitrary object chosen by the client.

Server hosts a  collection of receivers, each with  sets of nodes. One
such receiver  is mandatory, the  root receiver `n`  (null). Receivers
may be identified by any unique object.

If  a receiver  cannot  be  located, respond  with  toplevel error  id
`ReceiverNotFound`. If a node cannot be located, respond with toplevel
error id `NodeNotFound`.

The node namespace separator shall be '`/`', for example, in `math/add`.

The server is not required to respond to messages in the same order it
received them. The  identifiers are used instead. This  allows for the
possibility  of parallel  operations  on the  server-side. The  client
should   also   probably    provide   some   way   of   asynchronously
sending/receiving.

## The Future

### Double-precision floating point

- *Probably going to make it in, just not sure about the specifics.*

[IEEE 754 FP64](http://en.wikipedia.org/wiki/Double_precision_floating-point_format),
beginning with `f`.

Sign bit (bit 63), exponent (bit 52), fraction (bit 0).

### Meta

- *This could be useful later.*

`a`, followed by a dictionary of information, with keys, ending with '`.`'.

#### Example

    <client> a a:session-id i3759da4ea75133a00bb9c098b667e013.
             4:mode 6:normal .

### Objects

- *Not sure about this at all. Maybe it should be more like a structure?*
  - *That is, like* `o s6:FooBar s3:foo s3:bar` *where the client must already know about FooBar's format and parses accordingly.*

Same syntax as  a dictionary, with `o` instead  of `d`. They're marked
as  objects,  so  clients  may  treat  them  differently.  Any  client
libraries, however,  should just treat  this as it does  a dictionary,
with a different type.

    o s5:class s8:MyObject s4:num1 i2a. s4:num2 i539. .
    => Object{ class: "MyObject", num1: 42, num2: 1337 }
