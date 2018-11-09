using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointCloudTest : MonoBehaviour
{

    public int count;
    public Material material;
    public float width;
    public float height;

    public Texture2D mask;

    public Texture2D size;
    //public float width;
    //public float height;
    
    private Mesh m_Mesh;
    private MeshRenderer m_MeshRenderer;
    private MeshFilter m_MeshFilter;

	void Start ()
	{
	    m_Mesh = new Mesh();

	    List<Vector3> vlist = new List<Vector3>();
	    List<int> ilist = new List<int>();
	    for (int i = 0; i < count; i++)
	    {
	        float x = Random.Range(0.0f, 1.0f);
            float y = Random.Range(0.0f, 1.0f);
	        int pixX = (int) (mask.width-1-x*mask.width);
            int pixY = (int)(mask.height-1- y * mask.height);
	        float maskV = mask.GetPixel(pixX, pixY).r;
            float s = size.GetPixel(pixX, pixY).r;
            float randPriority = Random.Range(0.0f, 1.0f);
	        if (randPriority < maskV)
	        {
	            Vector3 p = new Vector3(-width*0.5f + width*x, s, -height*0.5f + height*y);
	            ilist.Add(vlist.Count);
                vlist.Add(p);
            }
        }
	    m_Mesh.SetVertices(vlist);
	    m_Mesh.SetIndices(ilist.ToArray(), MeshTopology.Points, 0);

	    m_MeshFilter = gameObject.AddComponent<MeshFilter>();
	    m_MeshRenderer = gameObject.AddComponent<MeshRenderer>();

	    m_MeshFilter.sharedMesh = m_Mesh;
	    m_MeshRenderer.sharedMaterial = material;
	}

    void OnDestroy()
    {
        if (m_Mesh)
            Destroy(m_Mesh);
        m_Mesh = null;
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.color = Color.green;

        Vector3 p0 = new Vector3(-width*0.5f, 0, -height*0.5f);
        Vector3 p1 = new Vector3(-width * 0.5f, 0, height * 0.5f);
        Vector3 p2 = new Vector3(width * 0.5f, 0, height * 0.5f);
        Vector3 p3 = new Vector3(width * 0.5f, 0, -height * 0.5f);

        Gizmos.DrawLine(p0, p1);
        Gizmos.DrawLine(p1, p2);
        Gizmos.DrawLine(p2, p3);
        Gizmos.DrawLine(p3, p0);
    }
}
