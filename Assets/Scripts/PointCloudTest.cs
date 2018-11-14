using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PointCloudTest : MonoBehaviour
{
    public List<float> grassDatas;

    public int count;
    public Material material;
    public float width;
    public float height;

    public Texture2D grass;
    public Texture2D mask;
    public Texture2D dirTex;

    public Texture2D size;
    public float dirOffset;
    //public float width;
    //public float height;
    
    private Mesh m_Mesh;
    private MeshRenderer m_MeshRenderer;
    private MeshFilter m_MeshFilter;

	void Start ()
	{
	    m_Mesh = new Mesh();

	    List<Vector3> vlist = new List<Vector3>();
	    List<Vector2> ulist = new List<Vector2>();
	    List<Vector2> u2list = new List<Vector2>();
	    List<int> ilist = new List<int>();

	    float uw = grassDatas.Count > 0 ? 1.0f/grassDatas.Count : 1.0f;

	    float totalPriority = 0;
	    for (var i = 0; i < grassDatas.Count; i++)
	    {
	        totalPriority += grassDatas[i];
	    }

	    for (int i = 0; i < count; i++)
	    {
	        float x = Random.Range(0.0f, 1.0f);
            float y = Random.Range(0.0f, 1.0f);
	        int pixX = (int) (mask.width-1-x*mask.width);
            int pixY = (int)(mask.height-1- y * mask.height);
	        float maskV = mask.GetPixel(pixX, pixY).r;
            float s = size.GetPixel(pixX, pixY).r;
	        Color dir = dirTex.GetPixel(pixX, pixY);
            float randPriority = Random.Range(0.0f, 1.0f);
	        if (randPriority < maskV)
	        {
	            Vector3 p = new Vector3(-width*0.5f + width*x, s, -height*0.5f + height*y);
	            Vector2 u = new Vector2((dir.r*2-1)*dirOffset, (dir.g*2-1)*dirOffset);
	            float rd = Random.Range(0.0f, totalPriority);
	            Vector2 u2 = new Vector2(0, uw);

	            float pri = 0.0f;
	            for (int j = 0; j < grassDatas.Count; j++)
	            {
	                if (rd < pri + grassDatas[j])
	                {
                        u2.x = j * uw;
                        u2.y = (j + 1) * uw;
	                    break;
	                }
                    pri += grassDatas[j];
	            }

	            ilist.Add(vlist.Count);
                vlist.Add(p);
	            ulist.Add(u);
	            u2list.Add(u2);
	        }
        }
	    m_Mesh.SetVertices(vlist);
	    m_Mesh.SetUVs(0, ulist);
	    m_Mesh.SetUVs(1, u2list);
	    m_Mesh.SetIndices(ilist.ToArray(), MeshTopology.Points, 0);

	    m_MeshFilter = gameObject.AddComponent<MeshFilter>();
	    m_MeshRenderer = gameObject.AddComponent<MeshRenderer>();

	    m_MeshFilter.sharedMesh = m_Mesh;
	    m_MeshRenderer.sharedMaterial = material;
	    material.SetTexture("_MainTex", grass);
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
