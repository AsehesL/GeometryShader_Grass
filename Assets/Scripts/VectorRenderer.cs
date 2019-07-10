using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VectorRenderer : MonoBehaviour
{
    public float aspect;
    public float size;
    public float height;

    private Camera m_Camera;
    private CommandBuffer m_CommandBuffer;
    private RenderTexture m_RenderTexture;

    private static VectorRenderer sInstance;

    public static VectorRenderer Instance
    {
        get
        {
            if (sInstance == null)
                sInstance = FindObjectOfType<VectorRenderer>();
            return sInstance;
        }
    }

    void Start()
    {
        m_Camera = CreateCamera();
        CreateRenderTarget();
    }

    void OnDestroy()
    {
        if (m_RenderTexture)
            Destroy(m_RenderTexture);
        if (m_CommandBuffer != null)
            m_CommandBuffer.Release();
    }

    void OnPostRender()
    {
        m_CommandBuffer.Clear();
        m_CommandBuffer.SetRenderTarget(m_RenderTexture);
        m_CommandBuffer.ClearRenderTarget(true, true, new Color(0.5f, 0.5f, 0, 1));

        Shader.SetGlobalMatrix("internal_VRProj", m_Camera.cullingMatrix);
        Shader.SetGlobalTexture("internal_VRTexture", m_RenderTexture);
    }

    public static void DrawMesh(Mesh mesh, Material material, Matrix4x4 matrix)
    {
        if(!Instance)
            return;
        Instance.m_CommandBuffer.DrawMesh(mesh, matrix, material);
    }

    private Camera CreateCamera()
    {
        Camera camera = GetComponent<Camera>();
        if (camera == null)
            camera = gameObject.AddComponent<Camera>();
        camera.orthographic = true;
        camera.backgroundColor = new Color(0.5f, 0.5f, 0, 1);
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.cullingMask = 0;
        camera.depth = 0;
        camera.allowHDR = false;
        camera.allowMSAA = false;
        camera.useOcclusionCulling = false;

        camera.orthographicSize = size;
        camera.nearClipPlane = 0;
        camera.farClipPlane = height;
        camera.aspect = aspect;
        return camera;
    }

    private void CreateRenderTarget()
    {
        m_CommandBuffer = new CommandBuffer();
        m_CommandBuffer.name = "[Cloud Render]";

        m_RenderTexture = CreateRenderTexture();
        m_Camera.targetTexture = m_RenderTexture;

        m_Camera.AddCommandBuffer(CameraEvent.BeforeImageEffectsOpaque, m_CommandBuffer);
    }

    private RenderTexture CreateRenderTexture()
    {
        var rt = new RenderTexture(1024, 1024, 16);
        rt.name = "Cloud";
        rt.wrapMode = TextureWrapMode.Clamp;
        return rt;
    }

    void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;

        Vector3 p0 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(-size * aspect, -size, 0));
        Vector3 p1 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(-size * aspect, size, 0));
        Vector3 p2 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(size * aspect, size, 0));
        Vector3 p3 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(size * aspect, -size, 0));

        Vector3 p4 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(-size * aspect, -size, height));
        Vector3 p5 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(-size * aspect, size, height));
        Vector3 p6 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(size * aspect, size, height));
        Vector3 p7 = transform.localToWorldMatrix.MultiplyPoint(new Vector3(size * aspect, -size, height));

        Gizmos.DrawLine(p0, p1);
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p0);

        Gizmos.DrawLine(p4, p5);
        Gizmos.DrawLine(p5, p6);
        Gizmos.DrawLine(p6, p7);
        Gizmos.DrawLine(p7, p4);

        Gizmos.DrawLine(p0, p4);
        Gizmos.DrawLine(p1, p5);
        Gizmos.DrawLine(p2, p6);
        Gizmos.DrawLine(p3, p7);

    }
}
