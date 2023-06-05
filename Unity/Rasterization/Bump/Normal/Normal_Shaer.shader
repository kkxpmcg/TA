// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Normal_Shaer"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(8.0,256)) = 128
        _MainTex ("Main Tex",2D) = "white" {}

        _BumpMap ("Normal Map", 2D) = "white" {}
        _BumpScale("Bump Scale",Float) = 1.0
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
                fixed4 _MainTex_ST;
                sampler2D _MainTex;

                sampler2D _BumpMap;
                float4 _BumpMap_ST;
                float _BumpScale;

                struct a2v {
                    float4 vertex : POSITION; //位置
                    float3 normal : NORMAL; //法线
                    float4 tangent : TANGENT; // 切线空间

                    float4 texcoord : TEXCOORD0; // 纹理坐标
                };

                struct v2f {
                    float4 pos : SV_POSITION;
                    fixed3 color : COLOR;

                    float3 worldNormal : TEXCOORD0; // 逐像素光照使用
                    float3 worldPos : TEXCOORD1; // 逐像素光照使用

                    float4 uv : TEXCOORD2; // 纹理坐标

                    float3 lightDir : TEXCOORD3;
                    float3 viewDir : TEXCOORD4;

                    // 从切线空间到世界空间的变换矩阵
                    float4 T: TEXCOORD5;
                    float4 B: TEXCOORD6;
                    float4 N: TEXCOORD7;
                };

                //逐顶点光照
                v2f vert(a2v v) {
                    v2f o;
                    //从模型空间转换到裁剪空间
                    o.pos = UnityObjectToClipPos(v.vertex); 

                    // 把模型空间的法线转换到世界空间,并且归一化
                    fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
                    o.worldNormal = worldNormal;

                    o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                    o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                    // o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);

                    // 把位置，法线，切线和副切线转换到世界空间
                    float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                    worldNormal = UnityObjectToWorldNormal(v.normal);
                    fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    fixed3 worldBinormal = cross(worldNormal,worldTangent) * v.tangent.w;

                    o.T = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                    o.B = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                    o.N = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                    //  计算副切线
                    //float3 binomral = cross(normalize(v.normal),normalize(v.tangent).xyz) * v.tangent.w;
                    //float3x3 rotation = float3x3(v.tangent.xyz,binomral,v.normal);

                    // use built-in macro
                    TANGENT_SPACE_ROTATION;

                    // 转换光线方向从对象空间到切线空间
                    o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;

                    // 转换视角方向动对象空间到切线空间
                    o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

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

                    // 世界坐标位置
                    float3 worldPos = float3(i.T.w,i.B.w,i.N.w);

                    // 世界光线位置和视角位置
                    fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                    fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                    // 切线空间下的光照方向和视角方向
                    fixed3 tangentLightDir = lightDir;
                    fixed3 tangentViewDir = viewDir;

                    //  sampler bumpTexture
                    fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);
                    
                    fixed3 tangentNormal;
                    // 计算切线法线
                    // tangentNormal.xy = (packedNormal*0.5+0.5) * _BumpScale;
                    // tangentNormal.z = sqrt(1.0 -  saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                    tangentNormal = UnpackNormal(packedNormal);
                    tangentNormal.xy *= _BumpScale;
                    tangentNormal.z = sqrt(1.0 -  saturate(dot(tangentNormal.xy,tangentNormal.xy)));

                    //  法线从切线空间转换到世界空间.  此处的tangentnormal是世界空间的法线
                    tangentNormal = normalize(half3(dot(i.T.xyz,tangentNormal),dot(i.B.xyz,tangentNormal),dot(i.N.xyz, tangentNormal)));


                    // 获取光源方向
                    //fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                    // // 兰伯特光照
                    // fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0,dot(worldLight,i.worldNormal));

                    // baseColor
                    fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                    //  // 获取环境光
                     fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; 

                    //  使用切线空间的法线和灯光方向计算 半兰伯特光照
                     fixed3 diffuse = _LightColor0.rgb * albedo * (dot(tangentLightDir,tangentNormal)*0.5+0.5);

                    // 根据世界光源和法线方向算出光源发射方向
                   // fixed3 reflectDir = normalize(reflect(-worldLight,i.worldNormal));

                    // half dir
                    fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

                    // 计算观察世界方向 = 相机位置减去着色点位置
                   // fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                         // 半程向量
                    //fixed3 halfDir = normalize(viewDir+worldLight);

                    // 计算高光
                    //fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,i.worldNormal)),_Gloss);

                    fixed3 specual = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir,tangentNormal)),_Gloss);
                    
                    //  高光 + 漫反射 + 环境光
                     diffuse = ambient + diffuse + specual;

                    return fixed4(diffuse,1.0);
                }
            ENDCG
        }
    }
    FallBack "Specular"
}
