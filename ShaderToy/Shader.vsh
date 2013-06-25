//
//  Shader.vsh
//  test
//
//  Created by Ricardo Chavarria on 5/5/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

attribute vec4 position;
attribute vec2 uv;

varying vec2 texCoords;

void main()
{
    texCoords = uv;
    gl_Position = position;
}
