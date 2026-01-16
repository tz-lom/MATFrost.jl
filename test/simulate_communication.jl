using Test
using MATFrost
using MATFrost._Types
using MATFrost._Read:  read_matfrostarray!
using MATFrost._Write: write_matfrostarray!
using MATFrost._ConvertToJulia
using MATFrost._ConvertToMATLAB
using Sockets
using Distributed

# @testset "Simulated MATLAB-Julia Communication" begin  
#     # Start the server in a separate task
#     host = "0.0.0.0"
#     port = 10001
    
#     server = listen(port)

#     server_task = Threads.@spawn begin
#         try
#             MATFrost.matfrostserve(host, port)
#         catch e
#             if !(e isa InterruptException)
#                 @error "Server error" exception=(e, catch_backtrace())
#                 rethrow(e)
#             end
#         end
#     end    
#     # Give server time to start
#     sleep(1)

#     @test istaskstarted(server_task)
#     # Connect client
#     client = accept(server)
#     @test client !== nothing
    
#     try
#         @testset "Simple Function Call" begin
#             # Prepare the call: CallMeta and arguments
#             # The call structure is a cell array with 2 elements:
#             # 1. CallMeta struct with fully_qualified_name and signature
#             # 2. Cell array with function arguments
            
#             # Create CallMeta struct
#             callmeta_struct = MATFrostArrayStruct(
#                 Int64[1],  # dims
#                 Symbol[:fully_qualified_name, :signature],  # field names
#                 MATFrostArrayAbstract[
#                     MATFrostArrayString(Int64[1], String["Base.sum"]),
#                     MATFrostArrayString(Int64[1], String["Vector{Float64}"]),
#                 ]
#             )
            
#             # Create arguments cell array
#             args_cell = MATFrostArrayCell(
#                 Int64[1],  # 1 argument
#                 MATFrostArrayAbstract[
#                     MATFrostArrayPrimitive{Float64}(Int64[2], Float64[5.0, 3.0])
#                 ]
#             )
            
#             # Combine into call structure
#             call_struct = MATFrostArrayCell(
#                 Int64[2],  # 2 elements
#                 MATFrostArrayAbstract[callmeta_struct, args_cell]
#             )

#             # Send the request
#             write_matfrostarray!(client, call_struct)
#             flush(client)
            
#             # Read the response
#             response = read_matfrostarray!(client)
            
#             # The response should be a struct with status, log, and value fields
#             @test response isa MATFrostArrayStruct
#             @test response.fieldnames == Symbol[:status, :log, :value]
            
#             # Extract status
#             status = _ConvertToJulia.convert_matfrostarray(String, response.values[1])
#             @test status == "SUCCESFUL"
            
#             # Extract result value
#             result = _ConvertToJulia.convert_matfrostarray(Float64, response.values[3])
#             @test result ≈ 8.0
#         end
        
#     finally
#         close(client)
#         # Stop the server
#         schedule(server_task, InterruptException(), error=true)
#     end
# end

@testset "Simulated MATLAB- real Julia Communication with IO capture" begin  
    # Start the server in a separate task
    host = "0.0.0.0"
    port = 10001
    
    server = listen(port)

    wid = addprocs(1)[1]
    Distributed.remotecall_eval(Main, wid, :(using MATFrost))
    remotecall(MATFrost.matfrostserve, wid, host, port; redirect_io=true)
    # Give server time to start
    sleep(1)

    # Connect client
    client = accept(server)
    @test client !== nothing
    
    try
        @testset "Simple Function Call" begin
            # Prepare the call: CallMeta and arguments
            # The call structure is a cell array with 2 elements:
            # 1. CallMeta struct with fully_qualified_name and signature
            # 2. Cell array with function arguments
            
            # Create CallMeta struct
            callmeta_struct = MATFrostArrayStruct(
                Int64[1],  # dims
                Symbol[:fully_qualified_name, :signature],  # field names
                MATFrostArrayAbstract[
                    MATFrostArrayString(Int64[1], String["Base.println"]),
                    MATFrostArrayString(Int64[1], String["String"]),
                ]
            )
            
            # Create arguments cell array
            args_cell = MATFrostArrayCell(
                Int64[1],  
                MATFrostArrayAbstract[
                    MATFrostArrayString(Int64[1], String["Hello"])
                ]
            )
            
            # Combine into call structure
            call_struct = MATFrostArrayCell(
                Int64[2],  # 2 elements
                MATFrostArrayAbstract[callmeta_struct, args_cell]
            )

            # Send the request
            write_matfrostarray!(client, call_struct)
            flush(client)
            
            # Read the response
            response = read_matfrostarray!(client)
            
            # The response should be a struct with status, log, and value fields
            @test response isa MATFrostIO            
            @test 1 == response.stream
            @test "MATFrost server connected. Ready for requests.\n" == response.content

            # Read the response
            response = read_matfrostarray!(client)
            
            # The response should be a struct with status, log, and value fields
            @test response isa MATFrostIO            
            @test 1 == response.stream
            @test "Hello\n" == response.content

            # # Read the response
            response = read_matfrostarray!(client)

            # # The response should be a struct with status, log, and value fields
            @test response isa MATFrostArrayStruct
            @test response.fieldnames == Symbol[:status, :log, :value]
            
            @test "SUCCESFUL" == _ConvertToJulia.convert_matfrostarray(String, response.values[1])
            @test response.values[3] isa MATFrostArrayStruct
            @test length(response.values[3].fieldnames) == 0
            @test length(response.values[3].values) == 0
        end
        
    finally
        close(client)
        # Stop the server
        rmprocs(wid)
    end
end