# Specification for Dr2

Dr2 (Devyn's RPC 2) is language independent. Here is the specification
for the protocol:

## Data Format

Dr2's data format is very bEncode (from BitTorrent)-like.

These characters should be ignored if not expected:

    0x09    CHARACTER TABULATION
    0x0A    LINE FEED (LF)
    0x20    SPACE

`.` closes a structure, similar to `e` in bEncode.

### Integer

`i` followed by hexadecimal `[0-9A-Fa-f]` number, ending with `.`.

    i33.
    => 51

### Double-precision floating point

[IEEE 754 FP64](http://en.wikipedia.org/wiki/Double_precision_floating-point_format),
beginning with `f`.

Sign bit (bit 63), exponent (bit 52), fraction (bit 0).

### List

`l`  followed  by  items  one  after another,  ending  with  `.`.  Not
necessarily all of the same type.

    l 3:foo i2. .
    => ["foo", 2]

### Dictionary

`d` followed  by items,  like a  list, but in  key, value,  key, value
order.   The dictionary  is not  necessarily in  any  particular order
(unordered map).  The keys and  values may be  of any type.  Ends with
`e`.

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

### Meta

`a`, followed by a dictionary of information, with keys, ending with `.`

#### Server-to-client

    key              description
    ---------------------------------------------------------------------------------
    s3:ext           A list of the server's supported extensions.

#### Client-to-server

    key              description
    ---------------------------------------------------------------------------------
    s3:ext           A list of the client's supported extensions.
    sa:session-id    Unique 128-bit integer, identifies the current session.
    s4:mode          Currently, 6:normal is the only value.
    s7:version       Version of the specification that the client conforms to.

#### Example

    c :: a a:session-id i3759da4ea75133a00bb9c098b667e013. 4:mode 6:normal .

### Error

`e`, then error id (string), then additional information (arb.)

    e s9:NameError d s7:message s24:undefined local variable .
    => Error{ id: "NameError", info: {message: "undefined local variable"} }

### Messages

List syntax,  first element is message id  (arbitrary object, uniquely
identifies  the  response)  second  element  is  treated  as  receiver
(arbitrary object, root is `n`), third is node name (string), and the
rest are the arguments (rev. order like lists).

    m i10000. n s8:math/add i2. i2. .
    => Message{ id: 65536, to: nil, node: "math/add", args: [2, 2] }

## Response

`r`, followed by the id  corresponding to the message, followed by the
return value.

    r i10000e i4.
    => Response{ id: 65536, value: 4 }

### Objects

Same syntax as  a dictionary, with `o` instead  of `d`. They're marked
as  objects,  so  clients  may  treat  them  differently.  Any  client
libraries, however,  should just treat  this as it does  a dictionary,
with a different type.

    o s5:class s8:MyObject s4:num1 i2a. s4:num2 i539. .
    => Object{ class: "MyObject", num1: 42, num2: 1337 }

### Pointer

Sometimes it is desirable to send  an object which must be accessed on
the server. The  pointer type `p` allows you to send  a pointer to the
client, which  can then  give you  that pointer as  the receiver  of a
message and  thereby call  methods on that  object. The syntax  is `p`
followed by an arbitrary identifier object.

    p iFF.
    => Pointer 255

## Protocol Examples

Dr2 is  designed to  be async compatible,  which is why  messages have
unique identifiers. The client may send two messages, and get the last
sent message's response  before the first one, if  the first one takes
longer and they run in parallel on the server.

    s :: 
    c :: m i1. i0. s9:factorial i10000. .      # Run 65536!.. this will take a while.
    c :: m i2. i0. s8:math/add  i2. i2. .      # Run 2 + 2.
    s :: r i2. i4.                             # Get response of 2 + 2, = 4.
    s :: r i1. iff23c771a4224f3ea955f44        # Get response of 65536!
               abb627cafecd3822f290c6e
	       f93cd162c00580000000000
	       00000.
