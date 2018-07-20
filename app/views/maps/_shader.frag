#ifdef GL_ES
precision highp float;
#endif

#define      PI 3.14159265358979323846264338327950288419716939937511 // mmm pie
#define     TAU 6.28318530717958647692528676655900576839433879875021 // pi * 2
#define HALF_PI 1.57079632679489661923132169163975144209858469968755 // pi / 2
#define PIO_360 0.00872664625997164788461845384244306356721435944271 // pi / 360
#define PIO_180 0.01745329251994329576923690768488612713442871888542 // pi / 180
#define PIU_180 57.2957795130823208767981548141051703324054724665643 // 180 / pi
#define       S 0.00000002495320233665337319798614601293674971774041 // .5 / (pi * R)
#define       R 6378137. // radius of the earth in meters
#define MAX_LAT 85.0511287798

uniform float u_time;
uniform float u_bins_per_radial;
uniform float u_map_zoom;
uniform float u_pixel_ratio;
uniform float u_color_modifier;
uniform  vec2 u_resolution;
uniform  vec2 u_radar_lat_lng;
uniform  vec2 u_map_pixel_origin;
uniform  vec2 u_map_pane_pos;
uniform  vec2 u_texture_size;
uniform sampler2D u_texture;

// Daniel Holden
// http://theorangeduck.com/page/avoiding-shader-conditionals
float when_eq(float x, float y) { return 1. - abs(sign(x - y)); }
float when_neq(float x, float y) { return abs(sign(x - y)); }
float when_gt(float x, float y) { return max(sign(x - y), 0.); }
float when_lt(float x, float y) { return max(sign(y - x), 0.); }
float when_gte(float x, float y) { return 1. - when_lt(x, y); }
float when_lte(float x, float y) { return 1. - when_gt(x, y); }
float and(float a, float b) { return a * b; }
float or(float a, float b) { return min(a + b, 1.); }
float xor(float a, float b) { return mod(a + b, 2.); }
float not(float a) { return 1. - a; }

// Íñigo Quílez
// https://www.shadertoy.com/view/MsS3Wc
vec3 hsv2rgb(vec3 c) {
  vec3 rgb = clamp(abs(mod(c.x*6.+vec3(0.,4.,2.),6.)-3.)-1.,0.,1.);
  rgb = rgb * rgb * (3. - 2. * rgb);
  return c.z * mix(vec3(1.), rgb, c.y);
}

// LOL
float round(float f) {
  return floor(f + .5);
}

vec2 ll_to_pixel(vec2 ll) {
  float scale = 256. * pow(2., u_map_zoom);
  float lat = max(min(MAX_LAT, ll.x), -MAX_LAT);
  float sin = sin(lat * PIO_180);
  float x = R * PIO_180 * ll.y;
  float y = (R * log((1. + sin) / (1. - sin))) / 2.;
  float tx = scale * ( S * x + .5);
  float ty = scale * (-S * y + .5);
  vec2 tp = vec2(round(tx), round(ty));
  vec2 lp = tp - u_map_pixel_origin + u_map_pane_pos;
  lp = vec2(round(lp.x) * u_pixel_ratio, round(lp.y) * u_pixel_ratio);
  return lp;
}

vec2 pixel_to_ll(vec2 p) {
  float scale = 256. * pow(2., u_map_zoom);
  float lpx = p.x / u_pixel_ratio;
  float lpy = (u_resolution.y - p.y) / u_pixel_ratio;
  vec2 tp = vec2(lpx, lpy) - u_map_pane_pos + u_map_pixel_origin;
  float utx = ((tp.x / scale) - .5) /  S;
  float uty = ((tp.y / scale) - .5) / -S;
  float lat = ((2. * atan(exp(uty / R))) - HALF_PI) * PIU_180;
  float lng = utx * PIU_180 / R;
  return vec2(lat, lng);
}

vec3 ll_to_vector(vec2 ll) {
  float lat = radians(ll.x);
  float lng = radians(ll.y);
  return vec3(cos(lat) * cos(lng), cos(lat) * sin(lng), sin(lat));
}

float vec_angle(vec3 a, vec3 b) {
  float sin = length(cross(a, b));
  float cos = dot(a, b);
  return atan(sin, cos);
}

float vec_angle_plane(vec3 a, vec3 b, vec3 c) {
  float sign = sign(dot(cross(a, b), c));
  float sin = length(cross(a, b)) * sign;
  float cos = dot(a, b);
  return atan(sin, cos);
}

float vec_distance(vec3 a, vec3 b) {
  return R * vec_angle(a, b);
}

float vec_bearing(vec3 a, vec3 b) {
  vec3 c1 = cross(a, b);
  vec3 c2 = cross(a, vec3(0., 0., 1.));
  float angle = vec_angle_plane(c1, c2, a);
  return mod(angle + PI, TAU);
}

float radar_value(vec3 v_frag, vec3 v_radar) {
  float distance = vec_distance(v_frag, v_radar);
  float angle = vec_bearing(v_frag, v_radar);
  float bin = distance / 1000.;
  float tx = (bin / u_bins_per_radial) * (u_bins_per_radial / u_texture_size.x);
  float ty = (angle / TAU) * (360. / u_texture_size.y);
  return texture2D(u_texture, vec2(tx, ty)).a;
}

vec4 radar_color(float value) {
  vec3 c = vec3(value * (1. + u_color_modifier), 1., 1.);
  float alpha = step(2. / 255., value); // 0 & 1: "no data" & "below threshold"
  return vec4(hsv2rgb(c), 1.) * alpha;
}

float circle(vec3 v_frag, vec3 v_center, float radius) {
  float distance = vec_distance(v_frag, v_center);
  return step(distance, radius);
}

float ring(vec3 v_frag, vec3 v_center, float radius, float thickness) {
  float c = circle(v_frag, v_center, radius + thickness);
  return c - circle(v_frag, v_center, radius);
}

void main() {
  vec3 v_frag = ll_to_vector(pixel_to_ll(gl_FragCoord.xy));
  vec3 v_radar = ll_to_vector(u_radar_lat_lng);
  vec4 radar_c = radar_color(radar_value(v_frag, v_radar));

  float thickness = 50000. / u_map_zoom;
  float radius = u_bins_per_radial * 1000.;
  float alpha = .123456789;
  float r = ring(v_frag, v_radar, radius, thickness);
  vec4 ring_c = vec4(vec3(0.), alpha) * r;

  // vec4 final_color = mix(radar_c, ring_c, ring_c.a); only necessary if overlapping
  vec4 final_color = radar_c + ring_c;

  gl_FragColor = final_color;
}

// void main() {
//   vec4 final_color = vec4(0.);

//   vec2 uv = ((gl_FragCoord.xy / u_resolution) * 2.) - 1.;
//   if (u_resolution.x > u_resolution.y) {
//     uv.x *= u_resolution.x / u_resolution.y;
//   } else {
//     uv.y *= u_resolution.y / u_resolution.x;
//   }

//   float r = .9;
//   float s = r * .001;
//   float l = length(uv);
//   float a = smoothstep(r + s, r - s, l);

//   float uv_a = atan(uv.y, uv.x);
//   uv_a = mod(uv_a + PI, TAU);
//   vec3 col = hsv2rgb(vec3(uv_a / TAU, 1., 1.));
//   final_color = vec4(col, 1.) * a;

//   float present = 0.;
//   for (float i = 0.; i < 360.; i += 1.) {
//     float x = (i / 360.) * (360. / u_texture_size.x);
//     float sy = 360. / u_texture_size.y;
//     float dy = 361. / u_texture_size.y;

//     float angle_start_enc = texture2D(u_texture, vec2(x, sy)).a;
//     float angle_delta_enc = texture2D(u_texture, vec2(x, dy)).a;

//     float s = radians(i + ((angle_start_enc * 255.) / 10.));
//     float d = radians((angle_delta_enc * 255.) / 10.);

//     present = or(present, and(when_gt(uv_a, s), when_lte(uv_a, s + d)));
//   }
//   final_color *= present;

//   gl_FragColor = final_color;
// }
