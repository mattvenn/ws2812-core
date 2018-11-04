{
  "version": "1.2",
  "package": {
    "name": "",
    "version": "",
    "description": "",
    "author": "",
    "image": ""
  },
  "design": {
    "board": "TinyFPGA-BX",
    "graph": {
      "blocks": [
        {
          "id": "edd67a3e-b0b7-4328-afb3-3677d7bb25cb",
          "type": "basic.output",
          "data": {
            "name": "led",
            "pins": [
              {
                "index": "0",
                "name": "PIN_3",
                "value": "B1"
              }
            ],
            "virtual": false
          },
          "position": {
            "x": 912,
            "y": 384
          }
        },
        {
          "id": "76411705-9375-4ca6-b7d2-3fbd9e1f1a89",
          "type": "basic.constant",
          "data": {
            "name": "width",
            "value": "12",
            "local": false
          },
          "position": {
            "x": -616,
            "y": 64
          }
        },
        {
          "id": "6d169c96-f111-4c01-a74d-d26cacae4f89",
          "type": "basic.constant",
          "data": {
            "name": "numleds",
            "value": "8",
            "local": false
          },
          "position": {
            "x": 256,
            "y": 152
          }
        },
        {
          "id": "6705784a-5e90-470f-bd41-c47ea3c277bf",
          "type": "basic.constant",
          "data": {
            "name": "clk_mhz",
            "value": "16",
            "local": false
          },
          "position": {
            "x": 576,
            "y": 152
          }
        },
        {
          "id": "7b7be8ab-339f-4b01-bef2-18de22431c7a",
          "type": "c4dd08263a85a91ba53e2ae2b38de344c5efcb52",
          "position": {
            "x": 8,
            "y": 592
          },
          "size": {
            "width": 96,
            "height": 64
          }
        },
        {
          "id": "84f3f05f-2cf0-48f2-8855-b586181721cc",
          "type": "c83dcd1d9ab420d911df81b3dfae04681559c623",
          "position": {
            "x": -16,
            "y": 480
          },
          "size": {
            "width": 96,
            "height": 64
          }
        },
        {
          "id": "dba1205b-4411-4576-85ad-752a211b4d7d",
          "type": "basic.code",
          "data": {
            "code": "\n\n    localparam LED_BITS = $clog2(NUM_LEDS);\n\n    /*\n    great information here:\n\n    * https://cpldcpu.wordpress.com/2014/01/14/light_ws2812-library-v2-0-part-i-understanding-the-ws2812/\n    * https://github.com/japaric/ws2812b/blob/master/firmware/README.md\n\n    period 1200ns:\n        * t on  800ns\n        * t off 400ns\n\n    end of frame/reset is > 50us. I had a bug at 50us, so increased to 65us\n\n    More recent ws2812 parts require reset > 280us. See: https://blog.particle.io/2017/05/11/heads-up-ws2812b-neopixels-are-about-to-change/\n\n    clock period at 12MHz = 83ns:\n        * t on  counter = 10, makes t_on  = 833ns\n        * t off counter = 5,  makes t_off = 416ns\n        * reset is 800 counts             = 65us\n\n    */\n    parameter t_on = $rtoi($ceil(CLK_MHZ*900/1000));\n    parameter t_off = $rtoi($ceil(CLK_MHZ*350/1000));\n    parameter t_reset = $rtoi($ceil(CLK_MHZ*280));\n    localparam t_period = $rtoi($ceil(CLK_MHZ*1250/1000));\n    localparam COUNT_BITS = $clog2(t_reset);\n\n    initial data = 0;\n\n    reg [23:0] led_reg [NUM_LEDS-1:0];\n\n    reg [LED_BITS-1:0] led_counter = 0;\n    reg [COUNT_BITS-1:0] bit_counter = 0;\n    reg [4:0] rgb_counter = 0;\n\n    localparam STATE_DATA  = 0;\n    localparam STATE_RESET = 1;\n    reg data;\n    reg [1:0] state = STATE_RESET;\n\n    reg [23:0] led_color;\n\n    // handle reading new led data\n    always @(posedge clk) begin\n        if(write)\n            led_reg[led_num] <= rgb_data;\n        led_color <= led_reg[led_counter];\n    end\n\n    integer i;\n    assign data_reg = data;\n    always @(posedge clk)\n        \n        // reset\n        if(reset) begin\n\t    //  In order to infer BRAM, can't have a reset condition\n\t    //  like this. But it will fail formal if you don't reset\n\t    //  it.\n            `ifdef NO_MEM_RESET\n\t    $display(\"Bypassing memory reset to allow BRAM\");\n\t    `else\n            // initialise led data to 0\n            for (i=0; i<NUM_LEDS; i=i+1)\n                led_reg[i] <= 0;\n\t    `endif\n\n            state <= STATE_RESET;\n            bit_counter <= t_reset;\n            rgb_counter <= 23;\n            led_counter <= NUM_LEDS - 1;\n            data <= 0;\n\n        // state machine to generate the data output\n        end else case(state)\n\n            STATE_RESET: begin\n                // register the input values\n                rgb_counter <= 5'd23;\n                led_counter <= NUM_LEDS - 1;\n                data <= 0;\n\n                bit_counter <= bit_counter - 1;\n\n                if(bit_counter == 0) begin\n                    state <= STATE_DATA;\n                    bit_counter <= t_period;\n                end\n            end\n\n            STATE_DATA: begin\n                // output the data\n                if(led_color[rgb_counter])\n                    data <= bit_counter > (t_period - t_on);\n                else\n                    data <= bit_counter > (t_period - t_off);\n\n                // count the period\n                bit_counter <= bit_counter - 1;\n\n                // after each bit, increment rgb counter\n                if(bit_counter == 0) begin\n                    bit_counter <= t_period;\n                    rgb_counter <= rgb_counter - 1;\n\n                    if(rgb_counter == 0) begin\n                        led_counter <= led_counter - 1;\n                        bit_counter <= t_period;\n                        rgb_counter <= 23;\n\n                        if(led_counter == 0) begin\n                            state <= STATE_RESET;\n                            led_counter <= NUM_LEDS - 1;\n                            bit_counter <= t_reset;\n                        end\n                    end\n                end \n            end\n\n        endcase\n\n    `ifdef FORMAL\n        // start in reset\n        initial restrict(reset);\n\n        // past valid signal\n        reg f_past_valid = 0;\n        always @(posedge clk)\n            f_past_valid <= 1'b1;\n\n        // check everything is zeroed on the reset signal\n        always @(posedge clk)\n            if (f_past_valid)\n                if ($past(reset)) begin\n                    assert(bit_counter == t_reset);\n                    assert(rgb_counter == 23);\n                    assert(led_reg[$past(led_num)] == 0);\n                end\n\n        always @(posedge clk) begin\n            assert(bit_counter <= t_reset);\n            assert(rgb_counter <= 23);\n            assert(led_counter <= NUM_LEDS - 1);\n\n            if(state == STATE_DATA) begin\n                assert(bit_counter <= t_period);\n                // led counter decrements\n                if($past(state) == STATE_DATA && $past(rgb_counter) == 0 && $past(bit_counter) == 0)\n                    assert(led_counter == $past(led_counter) - 1);\n            end\n\n            if(state == STATE_RESET) begin\n                assert(data == 0);\n                assert(bit_counter <= t_reset);\n            end\n        end\n\n        // leds < NUM_LEDSs\n        always @(posedge clk)\n            assume(led_num < NUM_LEDS);\n\n        // check that writes end up in the led register\n        always @(posedge clk)\n            if (f_past_valid)\n                if(!$past(reset) && $past(write))\n                    assert(led_reg[$past(led_num)] == $past(rgb_data));\n            \n    `endif\n    \n\n",
            "params": [
              {
                "name": "NUM_LEDS"
              },
              {
                "name": "CLK_MHZ"
              }
            ],
            "ports": {
              "in": [
                {
                  "name": "clk"
                },
                {
                  "name": "rgb_data",
                  "range": "[23:0]",
                  "size": 24
                },
                {
                  "name": "led_num",
                  "range": "[7:0]",
                  "size": 8
                },
                {
                  "name": "write"
                },
                {
                  "name": "reset"
                }
              ],
              "out": [
                {
                  "name": "data_reg"
                }
              ]
            }
          },
          "position": {
            "x": 144,
            "y": 312
          },
          "size": {
            "width": 640,
            "height": 200
          }
        },
        {
          "id": "a85f4e76-62fc-4cb6-bf97-b1f724753e82",
          "type": "6a50747141af6d1cfb3bb9d0093fb94862ff5a65",
          "position": {
            "x": -616,
            "y": 176
          },
          "size": {
            "width": 96,
            "height": 64
          }
        },
        {
          "id": "dc054d88-03c0-4c82-8711-416baf3f1943",
          "type": "basic.code",
          "data": {
            "code": "assign rgb = rgb_reg;\nassign led_num = led_num_reg;\nreg [7:0] led_num_reg;\nreg [23:0] rgb_reg = 0;\n\nalways @(posedge clk) begin\n    rgb_reg <= rgb_reg + 1;\n    led_num_reg <= led_num_reg + 1;\nend",
            "params": [],
            "ports": {
              "in": [
                {
                  "name": "clk"
                }
              ],
              "out": [
                {
                  "name": "rgb",
                  "range": "[23:0]",
                  "size": 24
                },
                {
                  "name": "led_num",
                  "range": "[7:0]",
                  "size": 8
                }
              ]
            }
          },
          "position": {
            "x": -536,
            "y": 328
          },
          "size": {
            "width": 400,
            "height": 192
          }
        }
      ],
      "wires": [
        {
          "source": {
            "block": "7b7be8ab-339f-4b01-bef2-18de22431c7a",
            "port": "19c8f68d-5022-487f-9ab0-f0a3cd58bead"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "reset"
          }
        },
        {
          "source": {
            "block": "84f3f05f-2cf0-48f2-8855-b586181721cc",
            "port": "19c8f68d-5022-487f-9ab0-f0a3cd58bead"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "write"
          }
        },
        {
          "source": {
            "block": "6d169c96-f111-4c01-a74d-d26cacae4f89",
            "port": "constant-out"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "NUM_LEDS"
          }
        },
        {
          "source": {
            "block": "6705784a-5e90-470f-bd41-c47ea3c277bf",
            "port": "constant-out"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "CLK_MHZ"
          }
        },
        {
          "source": {
            "block": "dc054d88-03c0-4c82-8711-416baf3f1943",
            "port": "rgb"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "rgb_data"
          },
          "size": 24
        },
        {
          "source": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "data_reg"
          },
          "target": {
            "block": "edd67a3e-b0b7-4328-afb3-3677d7bb25cb",
            "port": "in"
          }
        },
        {
          "source": {
            "block": "dc054d88-03c0-4c82-8711-416baf3f1943",
            "port": "led_num"
          },
          "target": {
            "block": "dba1205b-4411-4576-85ad-752a211b4d7d",
            "port": "led_num"
          },
          "size": 8
        },
        {
          "source": {
            "block": "76411705-9375-4ca6-b7d2-3fbd9e1f1a89",
            "port": "constant-out"
          },
          "target": {
            "block": "a85f4e76-62fc-4cb6-bf97-b1f724753e82",
            "port": "de2d8a2d-7908-48a2-9e35-7763a45886e4"
          }
        },
        {
          "source": {
            "block": "a85f4e76-62fc-4cb6-bf97-b1f724753e82",
            "port": "7e07d449-6475-4839-b43e-8aead8be2aac"
          },
          "target": {
            "block": "dc054d88-03c0-4c82-8711-416baf3f1943",
            "port": "clk"
          }
        }
      ]
    }
  },
  "dependencies": {
    "c4dd08263a85a91ba53e2ae2b38de344c5efcb52": {
      "package": {
        "name": "Bit 0",
        "version": "1.0.0",
        "description": "Assign 0 to the output wire",
        "author": "Jesús Arroyo",
        "image": "%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20width=%2247.303%22%20height=%2227.648%22%20viewBox=%220%200%2044.346456%2025.919999%22%3E%3Ctext%20style=%22line-height:125%25%22%20x=%22325.37%22%20y=%22315.373%22%20font-weight=%22400%22%20font-size=%2212.669%22%20font-family=%22sans-serif%22%20letter-spacing=%220%22%20word-spacing=%220%22%20transform=%22translate(-307.01%20-298.51)%22%3E%3Ctspan%20x=%22325.37%22%20y=%22315.373%22%20style=%22-inkscape-font-specification:'Courier%2010%20Pitch'%22%20font-family=%22Courier%2010%20Pitch%22%3E0%3C/tspan%3E%3C/text%3E%3C/svg%3E"
      },
      "design": {
        "graph": {
          "blocks": [
            {
              "id": "19c8f68d-5022-487f-9ab0-f0a3cd58bead",
              "type": "basic.output",
              "data": {
                "name": ""
              },
              "position": {
                "x": 608,
                "y": 192
              }
            },
            {
              "id": "b959fb96-ac67-4aea-90b3-ed35a4c17bf5",
              "type": "basic.code",
              "data": {
                "code": "// Bit 0\n\nassign v = 1'b0;",
                "params": [],
                "ports": {
                  "in": [],
                  "out": [
                    {
                      "name": "v"
                    }
                  ]
                }
              },
              "position": {
                "x": 96,
                "y": 96
              },
              "size": {
                "width": 384,
                "height": 256
              }
            }
          ],
          "wires": [
            {
              "source": {
                "block": "b959fb96-ac67-4aea-90b3-ed35a4c17bf5",
                "port": "v"
              },
              "target": {
                "block": "19c8f68d-5022-487f-9ab0-f0a3cd58bead",
                "port": "in"
              }
            }
          ]
        }
      }
    },
    "c83dcd1d9ab420d911df81b3dfae04681559c623": {
      "package": {
        "name": "Bit 1",
        "version": "1.0.0",
        "description": "Assign 1 to the output wire",
        "author": "Jesús Arroyo",
        "image": "%3Csvg%20xmlns=%22http://www.w3.org/2000/svg%22%20width=%2247.303%22%20height=%2227.648%22%20viewBox=%220%200%2044.346456%2025.919999%22%3E%3Ctext%20style=%22line-height:125%25%22%20x=%22325.218%22%20y=%22315.455%22%20font-weight=%22400%22%20font-size=%2212.669%22%20font-family=%22sans-serif%22%20letter-spacing=%220%22%20word-spacing=%220%22%20transform=%22translate(-307.01%20-298.51)%22%3E%3Ctspan%20x=%22325.218%22%20y=%22315.455%22%20style=%22-inkscape-font-specification:'Courier%2010%20Pitch'%22%20font-family=%22Courier%2010%20Pitch%22%3E1%3C/tspan%3E%3C/text%3E%3C/svg%3E"
      },
      "design": {
        "graph": {
          "blocks": [
            {
              "id": "19c8f68d-5022-487f-9ab0-f0a3cd58bead",
              "type": "basic.output",
              "data": {
                "name": ""
              },
              "position": {
                "x": 608,
                "y": 192
              }
            },
            {
              "id": "b959fb96-ac67-4aea-90b3-ed35a4c17bf5",
              "type": "basic.code",
              "data": {
                "code": "// Bit 1\n\nassign v = 1'b1;",
                "params": [],
                "ports": {
                  "in": [],
                  "out": [
                    {
                      "name": "v"
                    }
                  ]
                }
              },
              "position": {
                "x": 96,
                "y": 96
              },
              "size": {
                "width": 384,
                "height": 256
              }
            }
          ],
          "wires": [
            {
              "source": {
                "block": "b959fb96-ac67-4aea-90b3-ed35a4c17bf5",
                "port": "v"
              },
              "target": {
                "block": "19c8f68d-5022-487f-9ab0-f0a3cd58bead",
                "port": "in"
              }
            }
          ]
        }
      }
    },
    "6a50747141af6d1cfb3bb9d0093fb94862ff5a65": {
      "package": {
        "name": "PrescalerN",
        "version": "0.1",
        "description": "Parametric N-bits prescaler",
        "author": "Juan Gonzalez (Obijuan)",
        "image": ""
      },
      "design": {
        "graph": {
          "blocks": [
            {
              "id": "e19c6f2f-5747-4ed1-87c8-748575f0cc10",
              "type": "basic.input",
              "data": {
                "name": "",
                "clock": true
              },
              "position": {
                "x": 0,
                "y": 256
              }
            },
            {
              "id": "7e07d449-6475-4839-b43e-8aead8be2aac",
              "type": "basic.output",
              "data": {
                "name": ""
              },
              "position": {
                "x": 720,
                "y": 256
              }
            },
            {
              "id": "de2d8a2d-7908-48a2-9e35-7763a45886e4",
              "type": "basic.constant",
              "data": {
                "name": "N",
                "value": "22",
                "local": false
              },
              "position": {
                "x": 352,
                "y": 56
              }
            },
            {
              "id": "2330955f-5ce6-4d1c-8ee4-0a09a0349389",
              "type": "basic.code",
              "data": {
                "code": "//-- Number of bits of the prescaler\n//parameter N = 22;\n\n//-- divisor register\nreg [N-1:0] divcounter;\n\n//-- N bit counter\nalways @(posedge clk_in)\n  divcounter <= divcounter + 1;\n\n//-- Use the most significant bit as output\nassign clk_out = divcounter[N-1];",
                "params": [
                  {
                    "name": "N"
                  }
                ],
                "ports": {
                  "in": [
                    {
                      "name": "clk_in"
                    }
                  ],
                  "out": [
                    {
                      "name": "clk_out"
                    }
                  ]
                }
              },
              "position": {
                "x": 176,
                "y": 176
              },
              "size": {
                "width": 448,
                "height": 224
              }
            }
          ],
          "wires": [
            {
              "source": {
                "block": "2330955f-5ce6-4d1c-8ee4-0a09a0349389",
                "port": "clk_out"
              },
              "target": {
                "block": "7e07d449-6475-4839-b43e-8aead8be2aac",
                "port": "in"
              }
            },
            {
              "source": {
                "block": "e19c6f2f-5747-4ed1-87c8-748575f0cc10",
                "port": "out"
              },
              "target": {
                "block": "2330955f-5ce6-4d1c-8ee4-0a09a0349389",
                "port": "clk_in"
              }
            },
            {
              "source": {
                "block": "de2d8a2d-7908-48a2-9e35-7763a45886e4",
                "port": "constant-out"
              },
              "target": {
                "block": "2330955f-5ce6-4d1c-8ee4-0a09a0349389",
                "port": "N"
              }
            }
          ]
        }
      }
    }
  }
}