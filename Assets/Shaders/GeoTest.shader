Shader "Unlit/GeoTest"
{
	Properties
	{
		_Width ("Width", float) = 0.1
		_Height ("Height", float) = 0.4
		_MainTex ("Texture", 2D) = "white" {}
		_Cutoff ("Cutoff", range(0,1)) = 0.6
		_Factor ("Factor", float) = 0
		_Wind0 ("Wind0", vector) = (0, 0, 0, 0)
		_Wind1 ("Wind1", vector) = (0, 0, 0, 0)
		_Wind2 ("Wind2", vector) = (0, 0, 0, 0)
		_Wind3 ("Wind3", vector) = (0, 0, 0, 0)
		_BodyColor("BodyColor", color) = (1,1,1,1)
		_Transmittance("Transmittance", float) = 1
	}
	CGINCLUDE

		struct appdata {
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord2 : TEXCOORD1;
		};

		struct v2geo
		{
			float4 vertex : SV_POSITION;
			float size : TEXCOORD0;
			float2 dir : TEXCOORD1;
			float2 uv : TEXCOORD2;
		};

		float4 _Wind0;
		float4 _Wind1;
		float4 _Wind2;
		float4 _Wind3;

		float _Width;
		float _Height;

		float _Factor;

		sampler2D _MainTex;

		float _Cutoff;

		float2 CalculateSingleWindInfluence(float4 param, float2 pos) {
			float2 dir = float2(cos(param.x), sin(param.x));

			return dir*param.y*sin(dot(dir, pos) * param.z + _Time.y*param.w);
		}

		float2 CalculateWindInfluence(float2 pos) {
			float2 dir = CalculateSingleWindInfluence(_Wind0, pos);
			dir += CalculateSingleWindInfluence(_Wind1, pos);
			dir += CalculateSingleWindInfluence(_Wind2, pos);
			dir += CalculateSingleWindInfluence(_Wind3, pos);

			return dir;
		}

		float4 CalculateWind(float4 startPos, float2 dir, float len, float factor) {
			dir = dir * factor;
			float a = length(dir);
			dir /= a;
			float y = len * cos(a);
			float2 dis = len * sin(a) * dir;

			return float4(startPos.xyz + float3(dis.x, y, dis.y), 1.0);
		}
	ENDCG
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" }
		LOD 100

		Pass
		{
			Name "FORWARD"
			Tags { "LightMode"="ForwardBase" }
			cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile_fog
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct g2f
			{
				float4 pos : SV_POSITION;
				float3 worldPos : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float2 uv : TEXCOORD2;
				UNITY_FOG_COORDS(3)
				SHADOW_COORDS(4)
			};

			float4 _BodyColor;
			float _Transmittance;

			void AppendTriangle(g2f o, inout TriangleStream<g2f> os, float4 bottomPos, float4 topPos, float3 bottomNor, float3 topNor, float bottomV, float topV, float2 uv, float size) {
				float4 epos = bottomPos + float4(-_Width * size, 0, 0, 0);
				

				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.uv = float2(uv.x, bottomV);
				o.worldNormal = bottomNor;
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);

				epos = topPos + float4(-_Width * size, 0, 0, 0);
				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.worldNormal = topNor;
				o.uv = float2(uv.x, topV);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);

				epos = topPos + float4(_Width*size, 0, 0, 0);
				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.worldNormal = topNor;
				o.uv = float2(uv.y, topV);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);
				os.RestartStrip();


				epos = bottomPos + float4(-_Width * size, 0, 0, 0);
				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.worldNormal = bottomNor;
				o.uv = float2(uv.x, bottomV);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);

				epos = topPos + float4(_Width*size, 0, 0, 0);
				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.worldNormal = topNor;
				o.uv = float2(uv.y, topV);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);

				epos = bottomPos + float4(_Width*size, 0, 0, 0);
				o.pos = mul(UNITY_MATRIX_P, epos);
				o.worldPos = mul(UNITY_MATRIX_I_V, epos);
				o.worldNormal = bottomNor;
				o.uv = float2(uv.y, bottomV);
				UNITY_TRANSFER_FOG(o, o.pos);
				TRANSFER_SHADOW(o);
				os.Append(o);
				os.RestartStrip();
			}
			
			v2geo vert (appdata v)
			{
				v2geo o;
				//o.vertex = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)));
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.x, 0.0, v.vertex.z, 1.0));
				o.size = v.vertex.y;
				o.dir = v.texcoord.xy;
				o.uv = v.texcoord2;
				return o;
			}

			[maxvertexcount(24)]
			void geom(point v2geo i[1], inout TriangleStream<g2f> os) {
				g2f o;

				float2 dir = CalculateWindInfluence(i[0].vertex.xz) + i[0].dir.xy;
				float len = _Height * 0.25*i[0].size;

				float4 pos0 = i[0].vertex;
				float4 pos1 = CalculateWind(pos0, dir, len, 1);
				float4 pos2 = CalculateWind(pos1, dir, len, 1 + _Factor);
				float4 pos3 = CalculateWind(pos2, dir, len, 1 + _Factor * 2);
				float4 pos4 = CalculateWind(pos3, dir, len, 1 + _Factor * 3);

				float3 r = mul(UNITY_MATRIX_I_V, float4(1, 0, 0, 0)).xyz;
				float3 n0 = normalize(cross(r, pos1 - pos0));
				float3 n1 = normalize(cross(r, pos2 - pos1));
				float3 n2 = normalize(cross(r, pos3 - pos2));
				float3 n3 = normalize(cross(r, pos4 - pos3));

				pos0 = mul(UNITY_MATRIX_V, pos0);
				pos1 = mul(UNITY_MATRIX_V, pos1);
				pos2 = mul(UNITY_MATRIX_V, pos2);
				pos3 = mul(UNITY_MATRIX_V, pos3); 
				pos4 = mul(UNITY_MATRIX_V, pos4);

				AppendTriangle(o, os, pos0, pos1, n0, (n0+n1)*0.5, 0, 0.25, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos1, pos2, (n0 + n1)*0.5, (n1 + n2)*0.5, 0.25, 0.5, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos2, pos3, (n1 + n2)*0.5, (n2 + n3)*0.5, 0.5, 0.75, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos3, pos4, (n2 + n3)*0.5, n3, 0.75, 1.0, i[0].uv, i[0].size);
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
			
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos)

				float3 litDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
				float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));

				float ndvSign = sign(dot(i.worldNormal, viewDir));//通过法线和视线的点积判断当前的面的朝向
				float ndl = abs(dot(i.worldNormal, litDir))*0.5 + 0.5;

				float ndlS = 1 - saturate(max(0, dot(i.worldNormal, litDir)*ndvSign));//计算一个衰减值，其只影响背光面

				float3 lightCol = lerp(_LightColor0.rgb, _LightColor0.rgb * _BodyColor.rgb * col.rgb * _Transmittance, ndlS);

				col.rgb = col.rgb * (UNITY_LIGHTMODEL_AMBIENT.rgb + lightCol* ndl*atten);

				UNITY_APPLY_FOG(i.fogCoord, col);

				clip(col.a - _Cutoff);
				return col;
			}
			ENDCG
		}
		Pass{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma multi_compile_shadowcaster
			#include "UnityCG.cginc"

			struct g2f {
				V2F_SHADOW_CASTER;
				float2 uv:TEXCOORD1;
			};

			v2geo vert(appdata v)
			{
				v2geo o;
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.x, 0.0, v.vertex.z, 1.0));
				o.size = v.vertex.y;
				o.dir = v.texcoord.xy;
				o.uv = v.texcoord2;
				return o;
			}

			float4 ClipSpaceShadowCasterPos(float3 worldPos, float3 worldNormal)
			{
				if (unity_LightShadowBias.z != 0.0)
				{
					float3 wLight = normalize(UnityWorldSpaceLightDir(worldPos.xyz));

					float shadowCos = dot(worldNormal, wLight);
					float shadowSine = sqrt(1 - shadowCos*shadowCos);
					float normalBias = unity_LightShadowBias.z * shadowSine;

					worldPos.xyz -= worldNormal * normalBias;
				}

				return mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
			}

#ifdef SHADOWS_CUBE
			#define TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,wnor,opos) o.vec = wpos.xyz - _LightPositionRange.xyz; opos = mul(UNITY_MATRIX_VP, wpos);
#else
			#define TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,wnor,opos) \
				opos = ClipSpaceShadowCasterPos(wpos, wnor); \
				opos = UnityApplyLinearShadowBias(opos);
#endif

			void AppendTriangle(g2f o, inout TriangleStream<g2f> os, float4 bottomPos, float4 topPos, float3 bottomNor, float3 topNor, float bottomV, float topV, float2 uv, float size) {
				float4 epos = bottomPos + float4(-_Width * size, 0, 0, 0);
				float3 wpos = mul(UNITY_MATRIX_I_V, epos);

				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,bottomNor,o.pos)
				o.uv = float2(uv.x, bottomV);
				os.Append(o);

				epos = topPos + float4(-_Width * size, 0, 0, 0);
				wpos = mul(UNITY_MATRIX_I_V, epos);
				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,topNor,o.pos)
				o.uv = float2(uv.x, topV);
				os.Append(o);

				epos = topPos + float4(_Width*size, 0, 0, 0);
				wpos = mul(UNITY_MATRIX_I_V, epos);
				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,topNor,o.pos)
				o.uv = float2(uv.y, topV);
				os.Append(o);
				os.RestartStrip();


				epos = bottomPos + float4(-_Width * size, 0, 0, 0);
				wpos = mul(UNITY_MATRIX_I_V, epos);
				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,bottomNor,o.pos)
				o.uv = float2(uv.x, bottomV);
				os.Append(o);

				epos = topPos + float4(_Width*size, 0, 0, 0);
				wpos = mul(UNITY_MATRIX_I_V, epos);
				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,topNor,o.pos)
				o.uv = float2(uv.y, topV);
				os.Append(o);

				epos = bottomPos + float4(_Width*size, 0, 0, 0);
				wpos = mul(UNITY_MATRIX_I_V, epos);
				TRANSFER_GEO_SHADOW_CASTER_NOPOS(o,wpos,bottomNor,o.pos)
				o.uv = float2(uv.y, bottomV);
				os.Append(o);
				os.RestartStrip();
			}

			[maxvertexcount(24)]
			void geom(point v2geo i[1], inout TriangleStream<g2f> os) {
				g2f o;

				float2 dir = CalculateWindInfluence(i[0].vertex.xz) + i[0].dir.xy;
				float len = _Height * 0.25*i[0].size;

				float4 pos0 = i[0].vertex;
				float4 pos1 = CalculateWind(pos0, dir, len, 1);
				float4 pos2 = CalculateWind(pos1, dir, len, 1 + _Factor);
				float4 pos3 = CalculateWind(pos2, dir, len, 1 + _Factor * 2);
				float4 pos4 = CalculateWind(pos3, dir, len, 1 + _Factor * 3);

				float3 r = mul(UNITY_MATRIX_I_V, float4(1, 0, 0, 0)).xyz;
				float3 n0 = normalize(cross(r, pos1 - pos0));
				float3 n1 = normalize(cross(r, pos2 - pos1));
				float3 n2 = normalize(cross(r, pos3 - pos2));
				float3 n3 = normalize(cross(r, pos4 - pos3));

				pos0 = mul(UNITY_MATRIX_V, pos0);
				pos1 = mul(UNITY_MATRIX_V, pos1);
				pos2 = mul(UNITY_MATRIX_V, pos2);
				pos3 = mul(UNITY_MATRIX_V, pos3);
				pos4 = mul(UNITY_MATRIX_V, pos4);

				AppendTriangle(o, os, pos0, pos1, n0, (n0 + n1)*0.5, 0, 0.25, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos1, pos2, (n0 + n1)*0.5, (n1 + n2)*0.5, 0.25, 0.5, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos2, pos3, (n1 + n2)*0.5, (n2 + n3)*0.5, 0.5, 0.75, i[0].uv, i[0].size);
				AppendTriangle(o, os, pos3, pos4, (n2 + n3)*0.5, n3, 0.75, 1.0, i[0].uv, i[0].size);
			}

			float4 frag(g2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
			clip(col.a - _Cutoff);
				SHADOW_CASTER_FRAGMENT(i)
				
			}
			ENDCG
		}
	}
}
