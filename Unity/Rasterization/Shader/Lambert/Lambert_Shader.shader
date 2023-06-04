// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Lambert_Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        pass {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
                fixed4 _Color;
                #include "Lighting.cginc"

                #pragma vertex vert
                #pragma fragment frag

                struct a2v {
                    float4 vertex : POSITION; //位置
                    float3 normal : NORMAL; //法线
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    //fixed3 color : COLOR;

                    float3 worldNormal : TEXCOORD0; // 逐像素光照
                };

                //逐顶点光照
                v2f vert(a2v v) {
                    v2f o;
                    //从模型空间转换到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex); 

                    // 把模型空间的法线转换到世界空间,并且归一化
                    fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                    o.worldNormal = worldNormal;
                                       
                    // // 获取光源方向
                    // fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                    
                    // 获取环境光
                    //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 
 
                    // // 计算漫反射
                    // fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldLight,worldNormal));
                    
                    // o.color = ambient + diffuse;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET {

                    // 逐像素光照

                     // 获取环境光
                    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 

                      // 获取光源方向
                     fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                    // 兰伯特光照
                    // fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldLight,i.worldNormal));

                     // 半兰伯特光照
                     fixed3 diffuse = _LightColor0.rgb * _Color.rgb * (dot(worldLight,i.worldNormal)*0.5+0.5);

                     diffuse += ambient;

                    return fixed4(diffuse,1.0);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
