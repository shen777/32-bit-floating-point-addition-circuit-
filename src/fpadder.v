module fpadder (
    input  [31:0] src1,
    input  [31:0] src2,
    output [31:0] out
);
wire [31:0] forbig,forlil;
wire forsign;
wire [7:0]outexp,newoutexp,aftexp,e1,e2,e3;
wire [48:0]unnormalize,normaled,aftrounded,w1,w2,w3;
reg [48:0]done;
reg [7:0]doneexp,finishexp;
reg o;
reg [31:0] finish,finaloutput;
reg[22:0] inf;

compare compare(.src1(src1),.src2(src2),.big(forbig),.lil(forlil));
sum sum(.big(forbig),.lil(forlil),.sign(forsign),.outexp(outexp),.unnormalize(unnormalize));
normalized n1(.outexp(outexp),.unnormalized(unnormalize),.newoutexp(newoutexp),.normalized(normaled));
round r1(.bfrrounded(normaled),.bfrexp(newoutexp),.rounded(aftrounded),.aftexp(aftexp));

always@(*)begin

if(aftrounded[48]==1)begin
o=1'b0;//o=fail
done[48:0]=aftrounded[48:0];
doneexp[7:0]=aftexp[7:0];
end
else begin// no overflow
//o=1'b1;//o=succes

finish[30:23]=aftexp[7:0];
if(aftexp==255)begin
finish[22:0]=23'b000000000000000000000000;
end else begin
finish[22:0]=aftrounded[46:24];
end
if(finish[30:0]==0)begin
finish[31]=1'b0;
end
else begin
finish[31]=forsign;
end
end
end

assign w1[48:0]=done[48:0];
assign e1[7:0]=doneexp[7:0];
normalized n2(.outexp(e1),.unnormalized(w1),.newoutexp(e2),.normalized(w2));
round r2(.bfrrounded(w2),.bfrexp(e2),.rounded(w3),.aftexp(e3));

always@(*)begin
while(done[48]==1)begin

done[48:0]=w3[48:0];
doneexp[7:0]=e3[7:0];
end
if((doneexp==0)&&(done[47]==1))begin
doneexp=8'b00000001;
end
inf=23'b000000000000000000000000;
if(doneexp==11111111)begin
finish[22:0]=inf[22:0];
end
else begin
finish[22:0]=done[46:24];
end
finish[30:23]=doneexp[7:0];
/*if((doneexp[7:0]==8'b11111111)&&(done!=0))begin
done[46:24]=23'b000000000000000000000000;
end*/
o=1'b1;
end
always@(*)begin
if(o==1)begin
finish[22:0]=done[46:24];
finish[30:23]=doneexp[7:0];
//finish[22:0]=done[46:24];
/*if(finish[30:0]==0)begin
finish[31]=1'b0;
end
else begin
finish[31]=forsign;
end
inf=23'b000000000000000000000000;
if(doneexp==11111111)begin
finish[22:0]=inf[22:0];
end*/
end

end
assign out[31:0]=finish[31:0];
endmodule

module compare(
    input  [31:0] src1,
    input  [31:0] src2,
    output  [31:0] big,
    output  [31:0] lil
);
reg [7:0]src1exp,src2exp;
reg [22:0]src1fra,src2fra;
reg [31:0]bigg,lill;
always@(*)begin
src1exp[7:0]=src1[30:23];
src2exp[7:0]=src2[30:23];
src1fra[22:0]=src1[22:0];
src2fra[22:0]=src2[22:0];
if(src1exp>src2exp) begin
bigg[31:0]=src1[31:0];
lill[31:0]=src2[31:0];
 end
else if(src2exp>src1exp) begin
bigg[31:0]=src2[31:0];
lill[31:0]=src1[31:0];
 end
 else if(src2exp==src1exp) begin //src1exp=src2exp
 if(src1fra>src2fra) begin
 bigg[31:0]=src1[31:0];
 lill[31:0]=src2[31:0];
 end 
 else begin
 bigg[31:0]=src2[31:0];
 lill[31:0]=src1[31:0];
 end
end
end
assign big[31:0]=bigg[31:0];
assign lil[31:0]=lill[31:0];
endmodule

module sum(
input [31:0]big,
input [31:0]lil,
output sign,
output [7:0]outexp,
output [48:0]unnormalize
);
reg [7:0] bigexp,lilexp,expsub,finalexp;
reg [48:0] lilalu,bigalu,result;
reg bigsign,lilsign;


always@(*)begin
bigsign=big[31];
lilsign=lil[31];
bigexp[7:0]=big[30:23];
lilexp[7:0]=lil[30:23];


if(bigexp!=0)begin
bigalu[47]=1'b1;
 end

else if(bigexp==0) begin
bigalu[47]=1'b0;
bigexp=8'b00000001;// try
 end

if(lilexp!=0)begin
lilalu[47]=1'b1;
 end

else if(lilexp==0) begin
lilalu[47]=1'b0;
lilexp=8'b00000001;
 end
expsub=bigexp-lilexp;

bigalu[48]=0;
lilalu[48]=0;
bigalu[46:24]=big[22:0];
lilalu[46:24]=lil[22:0];
bigalu[23:0]=24'b000000000000000000000000;
lilalu[23:0]=24'b000000000000000000000000;

if(expsub!=0)begin
lilalu=lilalu>>expsub;
end
if(bigsign==lilsign)begin
result=bigalu+lilalu;
end
else if(bigsign!=lilsign) begin
result=bigalu-lilalu;
end
finalexp[7:0]=bigexp[7:0];
end
assign unnormalize[48:0]=result[48:0];
assign sign=big[31];
assign outexp=finalexp[7:0];

endmodule

module normalized(
input [7:0] outexp,
input [48:0]unnormalized,
output [7:0] newoutexp,
output [48:0]normalized
);
reg [7:0] exp,out;
reg x;
reg [48:0] normal,done;

always@(*)begin
exp[7:0]=outexp[7:0];
normal[48:0]=unnormalized[48:0];

if(exp==0)begin
if((normal[48]!=0)||(normal[47]!=0))begin// 48,47==0 不做
exp=8'b00000001;
normal=normal>>1;
   end
 else begin
 done[48:0]= normal[48:0];
 out[7:0]=exp[7:0];
 x=1'b1;
 end
  end
  
else begin //exp !=0
if(normal[48]==1)begin
exp=exp+1;
normal=normal>>1;
end
while((normal[48]==0)&&(normal[47]==0)&&(exp!=0))begin//origin exp!=0
exp=exp-1;
normal=normal<<1;
end
if((exp==0)&&(normal[47]==1))begin
exp=8'b00000001;
end
//可能有問題
done[48:0]= normal[48:0];
out[7:0]=exp[7:0];
x=1;
end
end

always@(*)begin
if(x==1)begin
done[48:0]= normal[48:0];
out[7:0]=exp[7:0];
end
end
assign newoutexp[7:0]=out[7:0];
assign normalized[48:0]=done[48:0];
endmodule

module round(
input [48:0]bfrrounded,
input [7:0]bfrexp,
output[48:0]rounded,
output[7:0]aftexp
);
reg [22:0] forrounded;
reg [48:0] aftrounded;

assign rounded[48:0]=aftrounded[48:0];
assign aftexp[7:0]=bfrexp[7:0];
always@(*)begin
forrounded[22:0]=bfrrounded[22:0];
aftrounded[48:24]=bfrrounded[48:24];
aftrounded[23:0]=24'b000000000000000000000000;
//forrounded[22:0]=aftrounded[22:0];
//aftrounded[48:24]=bftrounded[48:24];//改
//aftrounded[23:0]=24'b000000000000000000000000;//後面全都捨
//aftrounded[48:0]=bfrrounded[48:0];

if(bfrrounded[23]==0)begin//bfr afr
// 不加
//aftrounded[23:0]=24'b000000000000000000000000;
end
else if(bfrrounded[23]==1) begin //23=1
if((forrounded!=0)||(aftrounded[24]==1))begin
// 要加
//aftrounded[23:0]=24'b000000000000000000000000;
aftrounded=aftrounded+25'b1000000000000000000000000;
end
else begin //24=0 and 22:0=0 
// 不加
end
end

end



    // -------------------------------------- //
    //   \^o^/   Write your code here~  \^o^/ //
    // -------------------------------------- //
	
endmodule
