shader_type canvas_item;


void fragment() {
	
	float light_blue = 1.0;
	float dark_blue =  236.0/255.0;
	float border_blue = 96.0/255.0;
	float thr = 0.1;
	
	vec4 curr_color = texture(TEXTURE,UV); // Get current color of pixel
	
	if (curr_color.b == 1.0 && curr_color.r < 1.0)
	{
		COLOR = vec4(1.0, 145.0/255.0, 72.0/255.0, 1.0);
	}
	else if (curr_color.b == dark_blue)
	{
		COLOR = vec4(1.0, 85.0/255.0, 53.0/255.0, 1.0);
	}
	else if (curr_color.b == border_blue && curr_color.a > 0.0)
	{
		COLOR = vec4(92.0/255.0, 45.0/255.0, 77.0/255.0, 1.0);
	}
	else
	{
		COLOR = curr_color;
	}
	
}
