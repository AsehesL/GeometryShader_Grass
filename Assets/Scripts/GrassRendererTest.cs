using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GrassRendererTest : MonoBehaviour
{

    public ComputeShader computeShader;
    public Shader renderShader;

    public float area;
    public int size = 3000;

    public Transform point;
    public float clipSize;

    private struct GrassSeed
    {
        public Vector3 position;
        public float size;
    }

    private ComputeBuffer m_ComputeBuffer;
    private ComputeBuffer m_ResultBuffer;
    private ComputeBuffer m_ArgsBuffer;

    private uint[] m_Args = new uint[4] {1, 0, 0, 0};

    private GrassSeed[] m_Seeds;
    private int m_Stride;
    private int m_KernelIndex;

    private Material m_Material;

    private int m_WarpCount;
    
	void Start ()
	{
	    m_ArgsBuffer = new ComputeBuffer(1, m_Args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        m_ArgsBuffer.SetData(m_Args);

        m_WarpCount = Mathf.CeilToInt((float) size / 1024);

	    m_Seeds = new GrassSeed[size];
        m_Material = new Material(renderShader);

	    for (int i = 0; i < m_Seeds.Length; i++)
	    {
            GrassSeed seed = new GrassSeed();
	        seed.position = new Vector3(Random.Range(-area * 0.5f, area * 0.5f), 0.0f,
	            Random.Range(-area * 0.5f, area * 0.5f));
	        seed.size = Random.Range(0.3f, 1.0f);
	        m_Seeds[i] = seed;
	    }

	    m_Stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(GrassSeed));

        m_ComputeBuffer = new ComputeBuffer(size, m_Stride);
	    m_ResultBuffer = new ComputeBuffer(size, m_Stride);
        m_ComputeBuffer.SetData(m_Seeds);

	    m_KernelIndex = computeShader.FindKernel("CSMain");
        computeShader.SetBuffer(m_KernelIndex, "GrassSeeds", m_ComputeBuffer);
	    computeShader.SetBuffer(m_KernelIndex, "Args", m_ArgsBuffer);
	    computeShader.SetBuffer(m_KernelIndex, "Results", m_ResultBuffer);

        m_Material.SetBuffer("GrassSeeds", m_ResultBuffer);

    }
	
	void Update () {
		computeShader.SetVector("_Point", point.position);
        computeShader.SetFloat("_ClipSize", clipSize);

	    computeShader.Dispatch(m_KernelIndex, m_WarpCount, 1, 1);
    }

    void OnRenderObject()
    {
        m_Material.SetPass(0);
        //Graphics.DrawProcedural(MeshTopology.Points, 1, size);
        Graphics.DrawProceduralIndirect(MeshTopology.Points, m_ArgsBuffer);
        m_ArgsBuffer.SetData(m_Args);
    }

    void OnDestroy()
    {
        if (m_ComputeBuffer != null)
            m_ComputeBuffer.Release();
        if (m_Material)
            Destroy(m_Material);
    }
}
