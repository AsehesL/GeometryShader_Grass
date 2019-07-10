Shader "Unlit/VectorRenderTest"
{
    Properties
    {
		_Range ("Range", vector) = (1,1,1,1)
		_Offset ("Offset", float) = 0
    }
    SubShader
    {
        Pass
        {
			blend srcalpha oneminussrcalpha
			zwrite off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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
            };

			float4 _Range;
			float _Offset;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				float2 dir = i.uv - float2(0.5,0.5);

				float l = length(dir);

				float c = saturate(sin(l * _Range.x + _Offset * _Time.x)) * (1.0-saturate((l - _Range.y) * _Range.z));

				dir = lerp(float2(0, 0), dir, c) * 0.5 + 0.5;

                return fixed4(dir.xy, 0.0, c);
            }
            ENDCG
        }
    }
}
