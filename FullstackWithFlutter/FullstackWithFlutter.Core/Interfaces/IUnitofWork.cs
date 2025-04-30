using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IUnitofWork:IDisposable
    {
     
        IAppUserRepository AppUsers { get; }
        int Complete();
    }
}
