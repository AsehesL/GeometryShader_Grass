// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/CSRtTest"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag
			#pragma target 5.0
			
			#include "UnityCG.cginc"

			struct GrassSeed
			{
				float3 position;

				float2 texcoord;

				float2 direction;

				float scale;
			};

			StructuredBuffer<GrassSeed> _Seeds;

			struct v2g
			{
				float size : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			struct g2f {
				float4 pos : SV_POSITION;
			};
			
			v2g vert (uint vertex_id : SV_VertexID, uint instance_id : SV_InstanceID)
			{
				v2g o;
				o.vertex = float4(_Seeds[instance_id].position.xyz, 1.0);
				o.size = _Seeds[instance_id].scale;
				return o;
			}

			[maxvertexcount(6)]
			void geom(point v2g i[1], inout TriangleStream<g2f> os) {
				g2f o;
				UNITY_INITIALIZE_OUTPUT(g2f, o);

				float hsize = i[0].size * 0.5;
				float4 pos0 = i[0].vertex + float4(-hsize, 0.0, -hsize, 0.0);
				float4 pos1 = i[0].vertex + float4(-hsize, 0.0, hsize, 0.0);
				float4 pos2 = i[0].vertex + float4(hsize, 0.0, hsize, 0.0);
				float4 pos3 = i[0].vertex + float4(hsize, 0.0, -hsize, 0.0);

				o.pos = UnityObjectToClipPos(pos0);
				os.Append(o);

				o.pos = UnityObjectToClipPos(pos1);
				os.Append(o);

				o.pos = UnityObjectToClipPos(pos2);
				os.Append(o);
				os.RestartStrip();


				o.pos = UnityObjectToClipPos(pos0);
				os.Append(o);

				o.pos = UnityObjectToClipPos(pos2);
				os.Append(o);

				o.pos = UnityObjectToClipPos(pos3);
				os.Append(o);
				os.RestartStrip();

			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				return fixed4(1,1,1,1);
			}
			ENDCG
		}
	}
}
