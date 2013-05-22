//
//  Shader.fsh
//  test
//
//  Created by Ricardo Chavarria on 5/5/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

precision highp float;
precision lowp int;

uniform highp vec3      iResolution;        // viewport resolution (in pixels)
uniform float           iGlobalTime;        // shader playback time (in seconds)
                                            //uniform float         iChannelTime[4];    // channel playback time (in seconds)
                                            //uniform vec4          iMouse;             // mouse pixel coords. xy: current (if MLB down), zw: click
                                            //uniform samplerXX     iChannel0..3;       // input channel. XX = 2D/Cube
                                            //uniform vec4          iDate;              // (year, month, day, time in seconds)

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
