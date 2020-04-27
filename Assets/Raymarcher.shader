Shader "Raymarcher"
{
    SubShader
    {
        Pass
        {
	        Cull Front
			Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry +10" }
			LOD 100

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile SDF_SPHERE_INVERT SDF_KIFS

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
				float4 worldPos : TEXCOORD1;
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float4x4 _InverseProjectionMatrix;
			float4x4 _CameraToWorldMatrix;

			float _FocalLength;
			 
			float _MaxDepth;
			float _MinDist;
			float _Steps;
			
			float3 mod(float3 x, float3 y)
			{
				return x - y * floor(x/y);
			}

			float2 map(float3 pos) 
			{
				pos = mod(pos, 1.) - .5;
				return float2(length(pos) - 0.125, 1.);
			}

			float2 raymarch(in float3 pos, in float3 rd, in float depth)
			{
				float2 res = float2(depth, 0.);

				for (int i = 0; i < _Steps; i++)
				{
					float2 dist = map(pos + rd * res.x);

					if (dist.x < _MinDist) break;
					
					res.x += dist.x;	
					res.y = dist.y;

					if (res.x >= _MaxDepth) break;
				}
				return res;
			}

			// Ambient Occlusion by Inigo Quilez https://www.shadertoy.com/view/Xds3zN
			float calcAO( in float3 pos, in float3 nor )
			{
				float occ = 0.0;
				float sca = 1.0;
				for( int i=0; i<4; i++ )
				{
					float hr = 0.01 + 0.02*float(i)/4.0;
					float3 aopos =  nor * hr + pos;
					float dd = map( aopos );
					occ += -(dd-hr)*sca;
					sca *= .95;
				}
				return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
			}

            v2f vert (appdata v)
            {
                v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = v.uv;

                return o;
            }
	
			float3 calcNormal( in float3 pos )
			{
				float3 eps = float3( 0.001, 0.0, 0.0 );
				float3 nor = float3(map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        							map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        							map(pos+eps.yyx).x - map(pos-eps.yyx).x );
				return normalize(nor);
			}

            fixed4 frag (v2f i) : SV_Target
            {
				float3 col = 0.;

				float3 camPos = _WorldSpaceCameraPos;
				float3 camRay = normalize(i.worldPos - camPos);
				
				float2 raymarchResult = raymarch(camPos, camRay, 0.);
				float3 worldPos = camPos + camRay * raymarchResult.x;
				float3 normal = calcNormal(worldPos);
				col = normal * 0.5 + 0.5;		
				col = lerp(col, 0., raymarchResult.x / _MaxDepth);
						
				return float4(col, 1.);
				return raymarchResult.x;
			}
            ENDCG
        }
    }
}
