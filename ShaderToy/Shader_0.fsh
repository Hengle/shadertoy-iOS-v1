precision highp float;
precision lowp int;

uniform highp vec3      iResolution;        // viewport resolution (in pixels)
uniform float           iGlobalTime;        // shader playback time (in seconds)
//uniform float         iChannelTime[4];    // channel playback time (in seconds)
//uniform vec4          iMouse;             // mouse pixel coords. xy: current (if MLB down), zw: click
//uniform samplerXX     iChannel0..3;       // input channel. XX = 2D/Cube
//uniform vec4          iDate;              // (year, month, day, time in seconds)

void main(void)
{
	float activeTime = iGlobalTime * 1.5;
	vec3 col;
	float halfPhase = 3.5;
	float timeMorph = 0.0;
	vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;
    
	p *= 7.0;
	float a = atan(p.y,p.x);
	float r = sqrt(dot(p,p));
	
	if(mod(activeTime, 2.0 * halfPhase) < halfPhase)
		timeMorph = mod(activeTime, halfPhase);
	else
		timeMorph = (halfPhase - mod(activeTime, halfPhase));
    
	timeMorph = 2.0*timeMorph + 1.0;
	
	float w = 0.25 + 3.0*(sin(activeTime + 1.0*r)+ 3.0*cos(activeTime + 5.0*a)/timeMorph);
	float x = 0.8 + 3.0*(sin(activeTime + 1.0*r)+ 3.0*cos(activeTime + 5.0*a)/timeMorph);
	
	col = vec3(0.1,0.2,0.82)*1.1;
    
	gl_FragColor = vec4(col*w*x,1.0);
}
