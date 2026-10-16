// sda_iobuf.v - IOBUF wrapper for BD module-reference integration
module sda_iobuf(
    input  wire I,
    input  wire T,
    output wire O,
    inout  wire IO
);
    IOBUF iobuf_inst(.I(I), .O(O), .T(T), .IO(IO));
endmodule
