using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace FullstackWithFlutter.Core.Interfaces
{
    public interface IGenericRepository<T> where T : class
    {
        Task<T> Get(int id);
        Task<IEnumerable<T>> GetAll();
        Task<IEnumerable<T>> Find(System.Linq.Expressions.Expression<Func<T, bool>> predicate);
        Task Add(T entity);
        void Delete(T entity);
        void Update(T entity);
    }
}
