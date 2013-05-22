//
//  Shader.vsh
//  test
//
//  Created by Ricardo Chavarria on 5/5/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

attribute vec4 position;
attribute vec4 color;

varying lowp vec4 colorVarying;

void main()
{
    colorVarying = color;
    
    gl_Position = position;
}
