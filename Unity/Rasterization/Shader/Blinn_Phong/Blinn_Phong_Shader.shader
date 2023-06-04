// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Blinn_Phong_Shader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 128
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

                struct a2v {
                    float4 vertex : POSITION; //位置
                    float3 normal : NORMAL; //法线
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    fixed3 color : COLOR;

                    float3 worldNormal : TEXCOORD0; // 逐像素光照使用
                    float3 worldPos : TEXCOORD1; // 逐像素光照使用
                };

                //逐顶点光照
                v2f vert(a2v v) {
                    v2f o;
                    //从模型空间转换到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex); 

                    // 把模型空间的法线转换到世界空间,并且归一化
                    fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                    o.worldNormal = worldNormal;

                    // 逐顶点光照
                    // // 世界空间位置
                    // o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                                       
                    // // // 获取光源方向
                    // fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                    
                    // // 获取环境光
                    // fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 
 
                    // // // 计算漫反射 = 半兰伯特
                    // fixed3 diffuse = _LightColor0.rgb * _Color.rgb * (dot(worldLight,worldNormal)*0.5+0.5);

                    // // ********************************************************

                    // // 根据世界光源和法线方向算出光源发射方向
                    // fixed3 reflectDir = normalize(reflect(-worldLight,worldNormal));

                    // // 计算观察世界方向 = 相机位置减去着色点位置
                    // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld,v.vertex).xyz);

                    // // 计算高光
                    // fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                    
                    //  高光 + 漫反射 + 环境光
                    //  o.color = ambient + diffuse + specual;

                    return o;
                }

                fixed4 frag(v2f i) : SV_TARGET {

                    // 逐像素光照

                    //  // 获取环境光
                     fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz; 

                    // 获取光源方向
                    fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                    // // 兰伯特光照
                    // fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldLight,i.worldNormal));

                    //  // 半兰伯特光照
                     fixed3 diffuse = _LightColor0.rgb * _Color.rgb * (dot(worldLight,i.worldNormal)*0.5+0.5);

                    // 根据世界光源和法线方向算出光源发射方向
                    fixed3 reflectDir = normalize(reflect(-worldLight,i.worldNormal));

                    // 计算观察世界方向 = 相机位置减去着色点位置
                    fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                         // 半程向量
                    fixed3 halfDir = normalize(viewDir+worldLight);

                    // 计算高光
                    //fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);

                    fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                    
                    //  高光 + 漫反射 + 环境光
                     diffuse = ambient + diffuse + specual;

                    return fixed4(diffuse,1.0);
                }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
