const int MAX_MARCHING_STEPS = 127;
const float MIN_DIST = 0.0;
const float MAX_DIST = 10.0;
const float EPSILON = 0.0001;
const vec4 ORIGIN = vec4(0,0,0,1);

const float halfIdealCubeWidthKlein = 0.5773502692;
const vec4 idealCubeCornerKlein = vec4(halfIdealCubeWidthKlein, halfIdealCubeWidthKlein, halfIdealCubeWidthKlein, 1.0);

uniform int isStereo;
uniform int lightingModel;
uniform mat4 cameraProjection;
uniform vec2 screenResolution;
uniform vec4 cameraQuat;
uniform float fov;
uniform mat4 generators[6];
uniform mat4 invGenerators[6];
uniform mat4 currentBoost;
uniform mat4 leftCurrentBoost;
uniform mat4 rightCurrentBoost;
uniform vec4 leftEyeRotation;
uniform vec4 rightEyeRotation;
uniform mat4 cellBoost;
uniform mat4 invCellBoost;
uniform vec4 lightSourcePosition;
uniform int maxSteps;
//--------------------------------------------
//Scene Dependent Variables
//--------------------------------------------
uniform int sceneIndex;
uniform float halfCubeWidthKlein;
uniform float sphereRad;
uniform float horosphereSize;
uniform float planeOffset;

//Quaternion Math
vec3 qtransform( vec4 q, vec3 v ){
  return v + 2.0*cross(cross(v, -q.xyz ) + q.w*v, -q.xyz);
}

//Raymarch Functions
float unionSDF(float d1, float d2){
  return min(d1, d2);
}

float differenceSDF(float d1, float d2){
  return max(-d1, d2);
}

float weightedAverageSDF(float d1, float d2, float k){
  return (1.0-k)*d1 + k*d2;
}
