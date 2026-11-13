// Portal girdabı (animasyon kuralları: uTime, uSize, uIntensity, uColor uniform'ları).
//   uIntensity: boşta 0.15, şarj / açılış sırasında 1.0'a çıkar (SPEC §2.3 AC5)
//   uColor: portal yeşili ya da efsanevi için tehlike kırmızısı
// Portal uygulamadaki tek parlayan öğedir (SPEC §5.1).
// Çıktı önceden çarpılmıştır; parıltının dışı saydamdır.
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uIntensity;
uniform vec3 uColor;

out vec4 fragColor;

const vec3 INK = vec3(0.043, 0.035, 0.094);

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void main() {
  float halfSize = 0.5 * min(uSize.x, uSize.y);
  vec2 p = (FlutterFragCoord().xy - 0.5 * uSize) / halfSize;   // [-1, 1]
  float r = length(p);
  float a = atan(p.y, p.x);
  float k = clamp(uIntensity, 0.0, 1.0);

  const float R = 0.80;      // portal yarıçapı
  const float RIM = 0.045;   // mürekkep kenarın yarı genişliği

  // Girdap: açı 1/r ile bükülür, yoğunlukla daha hızlı döner.
  float speed = 0.5 + 2.6 * k;
  float swirl = a + 2.0 / (r + 0.18) - uTime * speed;
  float n = vnoise(p * 3.0 + vec2(uTime * 0.25, -uTime * 0.2));
  float bands = 0.5 + 0.5 * sin(swirl * 3.0 + n * 2.5);

  vec3 deep = uColor * 0.22;
  vec3 hot = mix(uColor, vec3(1.0), 0.45);
  vec3 col = mix(deep, uColor, bands);

  float core = exp(-r * r * (7.0 - 4.5 * k));
  col = mix(col, hot, core * (0.45 + 0.25 * k));

  // Sarmal boyunca içe çekilen parçacıklar; şarjda daha çok ve daha hızlı.
  float rings = 9.0;
  float flow = r * rings + uTime * (0.6 + 3.0 * k);
  // mod 14: açı +-pi'de bir tam tur atlar; iki tarafta aynı hücre
  // indeksi sol eksende görünür bir ek yeri oluşmasını önler.
  const float SECTORS = 14.0;
  vec2 cell = vec2(floor(flow), mod(floor((swirl / 6.2831853) * SECTORS), SECTORS));
  float pick = step(0.86 - 0.18 * k, hash(cell));
  float dotShape = smoothstep(0.35, 0.0, abs(fract(flow) - 0.5)) *
                   smoothstep(0.4, 0.0, abs(fract(swirl / 6.2831853 * SECTORS) - 0.5));
  col += hot * pick * dotShape * (0.25 + 0.6 * k);

  float inside = smoothstep(R, R - 0.02, r);
  float rim = smoothstep(RIM, RIM * 0.4, abs(r - R));

  // Kenarın dışında parıltı (şarjda daha güçlü).
  float glow = (r > R) ? exp(-(r - R) * 7.0) * (0.25 + 0.5 * k) : 0.0;

  vec3 rgb = col * inside;
  float alpha = inside;
  rgb = mix(rgb, INK, rim);
  alpha = max(alpha, rim);
  rgb += uColor * glow * (1.0 - alpha);
  alpha = clamp(alpha + glow * (1.0 - alpha), 0.0, 1.0);

  fragColor = vec4(rgb, alpha);
}
