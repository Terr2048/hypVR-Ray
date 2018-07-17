//--------------------------------------------
//Global Constants
//--------------------------------------------
const int MAX_MARCHING_STEPS = 127;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float EPSILON = 0.0001;
const vec4 ORIGIN = vec4(0,0,0,1);
//--------------------------------------------
//Generated Constants
//--------------------------------------------
const float halfIdealCubeWidthKlein = 0.5773502692;
const vec4 idealCubeCornerKlein = vec4(halfIdealCubeWidthKlein, halfIdealCubeWidthKlein, halfIdealCubeWidthKlein, 1.0);
//--------------------------------------------
//Global Variables
//--------------------------------------------
//mat4 totalFixMatrix = mat4(1.0);
vec4 globalSamplePoint = vec4 (0,0,0,1);
vec4 globalLightColor = vec4 (0,0,0,1);
//-------------------------------------------
//Translation & Utility Variables
//--------------------------------------------
uniform int isStereo;
uniform int geometry;
uniform vec2 screenResolution;
uniform float fov;
uniform mat4 invGenerators[6];
uniform mat4 currentBoost;
uniform mat4 leftCurrentBoost;
uniform mat4 rightCurrentBoost;
uniform mat4 cellBoost; 
uniform mat4 invCellBoost;
uniform int maxSteps;
//--------------------------------------------
//Lighting Variables & Global Object Variables
//--------------------------------------------
uniform vec4 lightPositions[4];
uniform vec4 lightIntensities[6]; //w component is the light's attenuation -- 6 since we need controllers
uniform int attnModel;
uniform sampler2D texture;
uniform int controllerCount; //Max is two
uniform mat4 controllerBoosts[2];
//uniform vec4 controllerDualPoints[6];
uniform mat4 globalObjectBoosts[8];
uniform mat4 invGlobalObjectBoosts[8];
uniform vec3 globalObjectRadii[8];
uniform int globalObjectTypes[8];
//--------------------------------------------
//Scene Dependent Variables
//--------------------------------------------
uniform vec4 halfCubeDualPoints[3];
uniform float halfCubeWidthKlein;
uniform float sphereRad;
uniform float tubeRad;
uniform float horosphereSize;
uniform float planeOffset;

// The type of cut (1=sphere, 2=horosphere, 3=plane) for the vertex opposite the fundamental simplex's 4th mirror.
// These integers match our values for the geometry of the honeycomb vertex figure.
// We'll need more of these later when we support more symmetry groups.
uniform int cut4;

//Quaternion Math
vec3 qtransform( vec4 q, vec3 v ){
  return v + 2.0*cross(cross(v, -q.xyz ) + q.w*v, -q.xyz);
}

//Raymarch Functions
float unionSDF(float d1, float d2){
  return min(d1, d2);
}

//--------------------------------------------------------------------
// Hyperbolic Functions
//--------------------------------------------------------------------
float cosh(float x){
  float eX = exp(x);
  return (0.5 * (eX + 1.0/eX));
}

float acosh(float x){ //must be more than 1
  return log(x + sqrt(x*x-1.0));
}

//--------------------------------------------------------------------
// Generalized Functions
//--------------------------------------------------------------------

vec4 geometryNormalize(vec4 v, bool toTangent);
vec4 geometryDirection(vec4 u, vec4 v);
float geometryDot(vec4 u, vec4 v);
float geometryDistance(vec4 u, vec4 v);
float geometryNorm(vec4 v){
  return sqrt(abs(geometryDot(v,v)));
}

vec4 pointOnGeodesic(vec4 u, vec4 vPrime, float dist);
bool isOutsideCell(vec4 samplePoint, out mat4 fixMatrix);

//--------------------------------------------------------------------
// Generalized SDFs
//--------------------------------------------------------------------

float globalSceneSDF(vec4 samplePoint, out vec4 lightIntensity, out int hitWhich);
float localSceneSDF(vec4 samplePoint);

float sphereSDF(vec4 samplePoint, vec4 center, float radius){
  return geometryDistance(samplePoint, center) - radius;
}

//--------------------------------------------------------------------
// Lighting Functions
//--------------------------------------------------------------------

//Essentially we are starting at our sample point then marching to the light
//If we make it to/past the light without hitting anything we return 1
/*otherwise the spot does not receive light from that light source
float shadowMarch(vec4 samplePoint, vec4 dirToLight, float distToLight){
  int fakeI = 0;
  float value = 0.0;
  mat4 fixMatrix;
  // Depth of our raymarcher 
  float globalDepth = MIN_DIST; float localDepth = MIN_DIST;
  // Values for local scene 
  vec4 localrO = samplePoint; vec4 localrD = dirToLight;
  // Stuff we don't need but have to pass as parameters 
  vec4 throwaway = vec4(0.0); int throwAlso = 0;
  // Are you ready boots? Start marchin'.
  for(int i = 0; i<MAX_MARCHING_STEPS; i++){
    if(fakeI >= maxSteps) break;
    fakeI++;
    vec4 localSamplePoint = pointOnGeodesic(localrO, localrD, localDepth);
    vec4 globalSamplePoint = pointOnGeodesic(samplePoint, dirToLight, globalDepth);
    if(isOutsideCell(localSamplePoint, fixMatrix)){
      vec4 newDirectionPoint = pointOnGeodesic(localrO, localrD, localDepth + 0.1);
      localrO = geometryNormalize(localSamplePoint*fixMatrix, false);
      newDirectionPoint = geometryNormalize(newDirectionPoint*fixMatrix, false);
      localrD = geometryDirection(localrO, newDirectionPoint);
      localDepth = MIN_DIST;
    }
    else{
      float localDist = localSceneSDF(localSamplePoint);
      float globalDist = globalSceneSDF(globalSamplePoint, throwaway, throwAlso);
      float dist = min(localDist, globalDist);
      if(globalDist < EPSILON)
        return 0.0;
      globalDepth += dist;
      localDepth += dist;
      if(globalDepth >= distToLight)
        return 1.0;
    }
  }
  return 1.0;
}

//Global only shadow march
float shadowMarch(vec4 samplePoint, vec4 dirToLight, float distToLight){
  int fakeI = 0;
  mat4 fixMatrix;
  // Depth of our raymarcher 
  float depth = MIN_DIST; 
  // Stuff we don't need but have to pass as parameters 
  vec4 throwaway = vec4(0.0); int throwAlso = 0;
  // Are you ready boots? Start marchin'.
  for(int i = 0; i<MAX_MARCHING_STEPS; i++){
    if(fakeI >= maxSteps) break;
    fakeI++;
    vec4 globalSamplePoint = pointOnGeodesic(samplePoint, dirToLight, depth);
    float dist = globalSceneSDF(globalSamplePoint, throwaway, throwAlso);
    if(dist < EPSILON)
      return 0.0;
    depth += dist;
    if(depth >= distToLight)
      return 1.0;
  }
  return 1.0;
}*/

vec4 texcube(sampler2D tex, vec4 samplePoint, vec4 N, float k, mat4 toOrigin){
    vec4 newSP = samplePoint * toOrigin;
    vec3 p = mod(newSP.xyz,1.0);
    vec3 n = geometryNormalize(N*toOrigin, true).xyz; //Very hacky you are warned
    vec3 m = pow(abs(n), vec3(k));
    vec4 x = texture2D(tex, p.yz);
    vec4 y = texture2D(tex, p.zx);
    vec4 z = texture2D(tex, p.xy);
    return (x*m.x + y*m.y + z*m.z) / (m.x+m.y+m.z);
}


float attenuation(float distToLight, vec4 lightIntensity){
  float att;
  if(attnModel == 1) //Inverse Linear
    att  = 0.75/ (0.01+lightIntensity.w * distToLight);  
  else if(attnModel == 2) //Inverse Square
    att  = 1.0/ (0.01+lightIntensity.w * distToLight* distToLight);
  else if(attnModel == 3) // Inverse Cube
    att = 1.0/ (0.01+lightIntensity.w*distToLight*distToLight*distToLight);
  else if(attnModel == 4) //Physical
    att  = 1.0/ (0.01+lightIntensity.w*cosh(2.0*distToLight)-1.0);
  else //None
    att  = 0.25; //if its actually 1 everything gets washed out
  return att;
}

vec3 phongModel(vec4 samplePoint, vec4 T, vec4 N, mat4 totalFixMatrix, mat4 invObjectBoost, bool isGlobal){
    vec4 V = -T; //Viewer is in the direction of the negative ray tangent vector
    float ambient = 0.1;
    vec3 baseColor = vec3(0.0,1.0,1.0);
    if(isGlobal)
      baseColor = texcube(texture, samplePoint, N, 4.0, cellBoost * invObjectBoost).xyz; 
    else
      baseColor = texcube(texture, samplePoint, N, 4.0, mat4(1.0)).xyz; 
    vec3 color = baseColor * ambient; //Setup up color with ambient component

    //--------------------------------------------
    //Lighting Calculations
    //--------------------------------------------
    for(int i = 0; i<6; i++){ //6 is the size of the lightPosition array
      vec4 translatedLightPosition, lightIntensity;
      float distToLight, att, shadow;
      //Controller Lights
      if(i>3){
        if(controllerCount == 0) break;
        else
          translatedLightPosition = ORIGIN*controllerBoosts[i-4]*currentBoost;
      }
      //Normal Lights
      else if(lightIntensities[i] != vec4(0.0)){
        translatedLightPosition = lightPositions[i]*invCellBoost*totalFixMatrix;
      }
      distToLight = geometryDistance(samplePoint, translatedLightPosition);
      lightIntensity = lightIntensities[i];
      att = attenuation(distToLight, lightIntensity);
      //Calculations - Phong Reflection Model
      vec4 L = geometryDirection(samplePoint, translatedLightPosition);
      shadow = 1.0;
      vec4 R = 2.0*geometryDot(L, N)*N - L;
      //Calculate Diffuse Component
      float nDotL = max(geometryDot(N, L),0.0);
      vec3 diffuse = lightIntensity.rgb * nDotL;
      //check if nDotL = 0  if so don't bother with shadowMarch
      if(nDotL == 0.0){
        shadow = 0.0;
      }
      //shadow = shadowMarch(samplePoint, L, distToLight);
      //Calculate Specular Component
      float rDotV = max(geometryDot(R, V),0.0);
      vec3 specular = lightIntensity.rgb * pow(rDotV,10.0);
      //Compute final color
      color += att*(shadow*((diffuse*baseColor) + specular));
      //Exit if there is only one controller
      if(controllerCount == 1 && i > 3) break;
    }
    return color;
}

/*else if(globalObjectTypes[i] == 1){ //cuboid
        vec4 dual0 = geometryDirection(globalObjectBoosts[i][3], globalObjectBoosts[i][3]*translateByVector(vec3(0.1,0.0,0.0)));
        vec4 dual1 = geometryDirection(globalObjectBoosts[i][3], globalObjectBoosts[i][3]*translateByVector(vec3(0.0,0.1,0.0)));
        vec4 dual2 = geometryDirection(globalObjectBoosts[i][3], globalObjectBoosts[i][3]*translateByVector(vec3(0.0,0.0,0.1)));
        objDist = geodesicCubeHSDF(absoluteSamplePoint, dual0, dual1, dual2, globalObjectRadii[i]);
      }*/