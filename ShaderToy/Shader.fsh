//
//  Shader.fsh
//  test
//
//  Created by Ricardo Chavarria on 5/5/13.
//  Copyright (c) 2013 Ricardo Chavarria. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
