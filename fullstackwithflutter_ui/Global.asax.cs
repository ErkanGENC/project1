protected void Application_BeginRequest(object sender, EventArgs e)
{
    if (HttpContext.Current.Request.HttpMethod == "OPTIONS")
    {
        HttpContext.Current.Response.AddHeader("Access-Control-Allow-Origin", "*");
        HttpContext.Current.Response.AddHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
        HttpContext.Current.Response.AddHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");
        HttpContext.Current.Response.AddHeader("Access-Control-Allow-Credentials", "true");
        HttpContext.Current.Response.StatusCode = 200;
        HttpContext.Current.Response.End();
    }
} 