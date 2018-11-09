Shader "Unlit/GeoTest"
{
	Properties
	{
		_Width ("Width", float) = 0.1
		_Height ("Height", float) = 0.4
		_MainTex ("Texture", 2D) = "white" {}
		_Cutoff ("Cutoff", range(0,1)) = 0.6
		_Factor ("Factor", float) = 0
		_Cloud0 ("Cloud0", vector) = (0, 0, 0, 0)
		_Cloud1 ("Cloud1", vector) = (0, 0, 0, 0)
		_Cloud2 ("Cloud2", vector) = (0, 0, 0, 0)
		_Cloud3 ("Cloud3", vector) = (0, 0, 0, 0)
	}
	SubShader
	{
		Tags { "RenderType"="TransparentCutout" "Queue"="Transparent" }
		LOD 100

		Pass
		{
			cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2g
			{
				float4 vertex : SV_POSITION;
				float size : TEXCOORD0;
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float _Width;
			float _Height;

			float4 _Cloud0;
			float4 _Cloud1;
			float4 _Cloud2;
			float4 _Cloud3;

			float _Cutoff;

			float _Factor;

			float2 CalculateSingleCloud(float4 param, float2 pos) {
				float2 dir = float2(cos(param.x), sin(param.x));

				return dir*param.y*sin(dot(dir, pos) * param.z + _Time.y*param.w);
			}

			float2 CalculateClouds(float2 pos) {
				float2 dir = CalculateSingleCloud(_Cloud0, pos);
				dir += CalculateSingleCloud(_Cloud1, pos);
				dir += CalculateSingleCloud(_Cloud2, pos);
				dir += CalculateSingleCloud(_Cloud3, pos);

				return dir;
			}

			float4 CalculateCloud(float4 startPos, float2 dir, float len, float factor) {
				dir = dir * factor;
				float a = length(dir);
				dir /= a;
				float y = len * cos(a);
				float2 dis = len * sin(a) * dir;

				return float4(startPos.xyz + float3(dis.x, y, dis.y), 1.0);
			}

			void AppendTriangle(g2f o, inout TriangleStream<g2f> os, float4 bottomPos, float4 topPos, float bottomV, float topV, float size) {
				o.vertex = mul(UNITY_MATRIX_P, bottomPos + float4(-_Width * size, 0, 0, 0));
				o.uv = float2(0, bottomV);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, topPos + float4(-_Width * size, 0, 0, 0));
				o.uv = float2(0, topV);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, topPos + float4(_Width*size, 0, 0, 0));
				o.uv = float2(1, topV);
				os.Append(o);
				os.RestartStrip();


				o.vertex = mul(UNITY_MATRIX_P, bottomPos + float4(-_Width * size, 0, 0, 0));
				o.uv = float2(0, bottomV);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, topPos + float4(_Width*size, 0, 0, 0));
				o.uv = float2(1, topV);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, bottomPos + float4(_Width*size, 0, 0, 0));
				o.uv = float2(1, bottomV);
				os.Append(o);
				os.RestartStrip();
			}
			
			v2g vert (appdata_base v)
			{
				v2g o;
				//o.vertex = mul(UNITY_MATRIX_V, mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0)));
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.x, 0.0, v.vertex.z, 1.0));
				o.size = v.vertex.y;
				return o;
			}

			[maxvertexcount(24)]
			void geom(point v2g i[1], inout TriangleStream<g2f> os) {
				g2f o;

				float2 dir = CalculateClouds(i[0].vertex.xz);
				float len = _Height * 0.25*i[0].size;

				float4 pos0 = i[0].vertex;
				float4 pos1 = CalculateCloud(pos0, dir, len, 1);
				float4 pos2 = CalculateCloud(pos1, dir, len, 1 + _Factor);
				float4 pos3 = CalculateCloud(pos2, dir, len, 1 + _Factor * 2);
				float4 pos4 = CalculateCloud(pos3, dir, len, 1 + _Factor * 3);

				pos0 = mul(UNITY_MATRIX_V, pos0);
				pos1 = mul(UNITY_MATRIX_V, pos1);
				pos2 = mul(UNITY_MATRIX_V, pos2);
				pos3 = mul(UNITY_MATRIX_V, pos3);
				pos4 = mul(UNITY_MATRIX_V, pos4);

				AppendTriangle(o, os, pos0, pos1, 0, 0.25, i[0].size);
				AppendTriangle(o, os, pos1, pos2, 0.25, 0.5, i[0].size);
				AppendTriangle(o, os, pos2, pos3, 0.5, 0.75, i[0].size);
				AppendTriangle(o, os, pos3, pos4, 0.75, 1.0, i[0].size);





				/*float4 pos0 = i[0].vertex;
				float4 pos1 = CalculateCloud(pos0, dir, _Height, 1);
				pos0 = mul(UNITY_MATRIX_V, pos0);
				pos1 = mul(UNITY_MATRIX_V, pos1);

				o.vertex = mul(UNITY_MATRIX_P, pos0 + float4(-_Width, 0, 0, 0));
				o.uv = float2(0, 0);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, pos1 + float4(-_Width, 0, 0, 0));
				o.uv = float2(0, 1);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, pos1 + float4(_Width, 0, 0, 0));
				o.uv = float2(1, 1);
				os.Append(o);
				os.RestartStrip();


				o.vertex = mul(UNITY_MATRIX_P, pos0 + float4(-_Width, 0, 0, 0));
				o.uv = float2(0, 0);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, pos1 + float4(_Width, 0, 0, 0));
				o.uv = float2(1, 1);
				os.Append(o);

				o.vertex = mul(UNITY_MATRIX_P, pos0 + float4(_Width, 0, 0, 0));
				o.uv = float2(1, 0);
				os.Append(o);
				os.RestartStrip();*/

				/*o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(-_Width,0,0));
				o.uv = float2(0, 0);
				os.Append(o);

				o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(-_Width, _Height, 0));
				o.uv = float2(0, 1);
				os.Append(o);

				o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(_Width, _Height, 0));
				o.uv = float2(1, 1);
				os.Append(o);
				os.RestartStrip();

				o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(-_Width, 0, 0));
				o.uv = float2(0, 0);
				os.Append(o);

				o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(_Width, _Height, 0));
				o.uv = float2(1, 1);
				os.Append(o);

				o.vertex = UnityObjectToClipPos(i[0].vertex.xyz + float3(_Width, 0, 0));
				o.uv = float2(1, 0);
				os.Append(o);
				os.RestartStrip();*/
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				clip(col.a - _Cutoff);
				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}
	}
}
