// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Ramp_Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 128
        _RampTex ("Ramp Tex", 2D) = "white" {}
    }
    SubShader
    {
        pass {
            Tags {"LightMode" = "ForwardBase"}

            CGPROGRAM
                
                #include "Lighting.cginc"

                #pragma vertex vert
                #pragma fragment frag

                fixed4 _Color;
                fixed4 _Specular;
                float _Gloss;

                sampler2D _RampTex;
                fixed4 _RampTex_ST;

                struct a2v {
                    float4 vertex : POSITION; //位置
                    float3 normal : NORMAL; //法线

                    float4 texcoord : TEXCOORD0; // 纹理坐标
                };

                struct v2f {
                    float4 pos : SV_POSITION;

                    float3 worldNormal : TEXCOORD0; // 逐像素光照使用
                    float3 worldPos : TEXCOORD1; // 逐像素光照使用

                    float2 uv : TEXCOORD2; // 纹理坐标
                };

                //逐顶点光照
                v2f vert(a2v v) {
                    v2f o;
                    //从模型空间转换到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex); 

                    // 把模型空间的法线转换到世界空间,并且归一化
                    fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                    o.worldNormal = worldNormal;

                    o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                    o.uv = v.texcoord.xy * _RampTex_ST.xy + _RampTex_ST.zw;
                    // o.uv = TRANSFORM_TEX(v.texcoord,_RampTex);

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET {

                    // 逐像素光照
                
                    // 世界法线
                    fixed3 worldNormal = normalize(i.worldNormal);

                    // 世界光照方向
                    fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                    // 观察方向
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                    //  获取环境光
                     fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 

                    //  半兰伯特光照
                     fixed halfLambert = dot(worldNormal,worldLightDir) * 0.5 + 0.5;

                     fixed3 diffuseColor = tex2D(_RampTex,fixed2(halfLambert,halfLambert)).rgb * _Color.rgb;
                     
                     // 漫反射
                     fixed3 diffuse = _LightColor0.rgb * diffuseColor;

                     // 半程向量
                    fixed3 halfDir = normalize(viewDir+worldLightDir);

                    //高光
                    fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,worldNormal)),_Gloss);
                    
                    //  高光 + 漫反射 + 环境光
                     diffuse = ambient + diffuse + specual;

                    return fixed4(diffuse,1.0);
                }
            ENDCG
        }
    }
    FallBack "Specular"
}