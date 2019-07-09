using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassRenderer : MonoBehaviour {

    /// <summary>
    /// 草的种子结构体
    /// </summary>
    private struct GrassSeed
    {
        /// <summary>
        /// 种子的世界坐标
        /// </summary>
        public Vector3 position;
        /// <summary>
        /// 草的mesh的采样uv
        /// </summary>
        public Vector2 texcoord;
        /// <summary>
        /// 初始方向偏移（从方向贴图中获取的具有一定随机性的方向，确保草不是笔直向上的）
        /// </summary>
        public Vector2 direction;
        /// <summary>
        /// 草mesh的缩放比例
        /// </summary>
        public float scale;
    }

    public List<float> grassDatas;
    public int count;
    public float areaWidth;
    public float areaHeight;

    public float grassWidth;
    public float grassHeight;

    public Texture2D grass;
    public Texture2D mask;
    public Texture2D dirTex;

    public Texture2D size;
    public float sizeBegin;
    public float dirOffset;

    public Camera cullingCamera;

    //public Transform point;
    //public float clipSize;

    /// <summary>
    /// 处理草种子的生成与剔除
    /// </summary>
    public ComputeShader computeShader;

    public Material material;

    private ComputeBuffer m_GrassBuffer;
    private ComputeBuffer m_ArgsBuffer;
    private ComputeBuffer m_ResultBuffer;

    private GrassSeed[] m_Seeds;
    private uint[] m_Args = {1, 0, 0, 0};

    private int m_CullingKernelIndex;

    private int m_DispatchCount;

    private float m_MaxSize;

    private int m_RenderCount;

    void Start ()
    {
        GenerateGrassSeeds();

        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(GrassSeed));
        m_DispatchCount = Mathf.CeilToInt((float)m_RenderCount / 1024);

        m_ArgsBuffer = new ComputeBuffer(1, m_Args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        m_GrassBuffer = new ComputeBuffer(m_RenderCount, stride);
        m_ResultBuffer = new ComputeBuffer(m_RenderCount, stride);

        m_CullingKernelIndex = computeShader.FindKernel("Culling");

        m_GrassBuffer.SetData(m_Seeds);
        m_ArgsBuffer.SetData(m_Args);

        computeShader.SetBuffer(m_CullingKernelIndex, "_Seeds", m_GrassBuffer);
        computeShader.SetBuffer(m_CullingKernelIndex, "_Args", m_ArgsBuffer);
        computeShader.SetBuffer(m_CullingKernelIndex, "_Result", m_ResultBuffer);

        m_MaxSize = Mathf.Max(grassHeight, grassWidth * 0.5f);

        material.SetBuffer("_Seeds", m_ResultBuffer);
        material.SetFloat("_Width", grassWidth);
        material.SetFloat("_Height", grassHeight);
        material.SetTexture("_MainTex", grass);
    }

    void OnDestroy()
    {
        if (m_GrassBuffer != null)
            m_GrassBuffer.Release();
        if (m_ArgsBuffer != null)
            m_ArgsBuffer.Release();
        if (m_ResultBuffer != null)
            m_ResultBuffer.Release();
    }

    void Update()
    {
        
        computeShader.SetFloat("_MaxSize", m_MaxSize);
        //computeShader.SetVector("_Point", point.position);
        //computeShader.SetFloat("_ClipSize", clipSize);

        computeShader.Dispatch(m_CullingKernelIndex, m_DispatchCount, 1, 1);
    }

    void OnRenderObject()
    {
        if (Camera.current != cullingCamera)
            return;
        Matrix4x4 projection = Camera.current.projectionMatrix * Camera.current.worldToCameraMatrix;
        computeShader.SetMatrix("_Projection", projection);


        material.SetPass(0);
        //Graphics.DrawProcedural(MeshTopology.Points, 1, m_RenderCount);
        Graphics.DrawProceduralIndirect(MeshTopology.Points, m_ArgsBuffer);

        
        m_ArgsBuffer.SetData(m_Args);
    }

    private void GenerateGrassSeeds()
    {
        //m_Seeds = new GrassSeed[count];
        List<GrassSeed> seeds = new List<GrassSeed>();

        float uw = grassDatas.Count > 0 ? 1.0f / grassDatas.Count : 1.0f;

        float totalPriority = 0;
        for (var i = 0; i < grassDatas.Count; i++)
        {
            totalPriority += grassDatas[i];
        }

        for (int i = 0; i < count; i++)
        {
            float x = Random.Range(0.0f, 1.0f);
            float y = Random.Range(0.0f, 1.0f);
            int pixX = (int)(mask.width - 1 - x * mask.width);
            int pixY = (int)(mask.height - 1 - y * mask.height);
            float maskV = mask.GetPixel(pixX, pixY).r;
            float s = sizeBegin + (1.0f - sizeBegin) * size.GetPixel(pixX, pixY).r;
            Color dir = dirTex.GetPixel(pixX, pixY);
            float randPriority = Random.Range(0.0f, 1.0f);
            if (randPriority < maskV)
            {
                Vector3 p = new Vector3(-areaWidth * 0.5f + areaWidth * x, 0, -areaHeight * 0.5f + areaHeight * y);
                Vector2 d = new Vector2((dir.r * 2 - 1) * dirOffset, (dir.g * 2 - 1) * dirOffset);
                float rd = Random.Range(0.0f, totalPriority);
                Vector2 u = new Vector2(0, uw);

                float pri = 0.0f;
                for (int j = 0; j < grassDatas.Count; j++)
                {
                    if (rd < pri + grassDatas[j])
                    {
                        u.x = j * uw;
                        u.y = (j + 1) * uw;
                        break;
                    }
                    pri += grassDatas[j];
                }

                GrassSeed seed = new GrassSeed()
                {
                    position = p,
                    texcoord = u,
                    direction = d,
                    scale = s
                };

                seeds.Add(seed);
            }
        }

        m_Seeds = seeds.ToArray();
        m_RenderCount = m_Seeds.Length;
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;

        Vector3 p0 = new Vector3(-areaWidth * 0.5f, 0, -areaHeight * 0.5f);
        Vector3 p1 = new Vector3(-areaWidth * 0.5f, 0, areaHeight * 0.5f);
        Vector3 p2 = new Vector3(areaWidth * 0.5f, 0, areaHeight * 0.5f);
        Vector3 p3 = new Vector3(areaWidth * 0.5f, 0, -areaHeight * 0.5f);

        Gizmos.DrawLine(p0, p1);
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p0);
    }
}
