shader_type canvas_item;

uniform vec4 modulate = vec4(1.0);

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = texture(TEXTURE, UV);
	
	if (color.a == 1.0){
    if (color.rgb != vec3(1.0) && color.rgb != vec3(0.0)){
        	color *= modulate;
    	}
	}
	COLOR = color;
	
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
