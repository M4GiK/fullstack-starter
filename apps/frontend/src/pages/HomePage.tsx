import { useContext, useEffect, useState } from 'react';
import { AuthContext } from '../context/AuthContext';
import { getAllUsersExtended } from '../api/queries/getAllUsersExtended';
import { User } from '../api/types/user';

export default function HomePage() {
  const { userData } = useContext(AuthContext);
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (userData) {
      fetchUsers();
    }
  }, [userData]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const userList = await getAllUsersExtended();
      setUsers(userList);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  if (!userData) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-teal-50 to-emerald-100">
        <div className="relative overflow-hidden">
          <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-24">
            <div className="text-center">
              <h1 className="text-4xl sm:text-5xl font-bold text-slate-900 mb-6 leading-tight">
                Monorepo Starter.{' '}
                <span className="bg-gradient-to-r from-teal-600 to-emerald-600 bg-clip-text text-transparent">
                  Everything set up for you.
                </span>
              </h1>
              <p className="text-lg text-slate-600 mb-8">
                Zaloguj się, aby zobaczyć listę zarejestrowanych użytkowników.
              </p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-teal-50 to-emerald-100">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 lg:py-12">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-slate-900 mb-2">
            Witaj, {userData.email}! 👋
          </h1>
          <p className="text-slate-600">
            Lista wszystkich zarejestrowanych użytkowników (z backend-extended):
          </p>
        </div>

        {/* Users List */}
        <div className="bg-white rounded-lg shadow-sm border border-slate-200">
          <div className="px-6 py-4 border-b border-slate-200">
            <h2 className="text-lg font-semibold text-slate-900">
              Zarejestrowani użytkownicy ({users.length})
            </h2>
          </div>

          <div className="p-6">
            {loading && (
              <div className="text-center py-8">
                <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-teal-600"></div>
                <p className="mt-2 text-slate-600">Ładowanie użytkowników...</p>
              </div>
            )}

            {error && (
              <div className="bg-red-50 border border-red-200 rounded-md p-4 mb-4">
                <p className="text-red-700">❌ Błąd: {error}</p>
                <button
                  onClick={fetchUsers}
                  className="mt-2 px-3 py-1 bg-red-600 text-white text-sm rounded hover:bg-red-700"
                >
                  Spróbuj ponownie
                </button>
              </div>
            )}

            {!loading && !error && users.length === 0 && (
              <div className="text-center py-8 text-slate-500">
                <p>Brak zarejestrowanych użytkowników.</p>
              </div>
            )}

            {!loading && !error && users.length > 0 && (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200">
                  <thead className="bg-slate-50">
                    <tr>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                        ID
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                        Email
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                        Status
                      </th>
                      <th className="px-4 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                        Data rejestracji
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-slate-200">
                    {users.map((user) => (
                      <tr key={user.id} className="hover:bg-slate-50">
                        <td className="px-4 py-3 text-sm text-slate-900 font-mono">
                          {user.id.substring(0, 8)}...
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-900">
                          {user.email}
                        </td>
                        <td className="px-4 py-3 text-sm">
                          <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                            user.isDeleted
                              ? 'bg-red-100 text-red-800'
                              : 'bg-green-100 text-green-800'
                          }`}>
                            {user.isDeleted ? 'Usunięty' : 'Aktywny'}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {new Date(user.createdAt).toLocaleDateString('pl-PL', {
                            year: 'numeric',
                            month: 'short',
                            day: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit'
                          })}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        {/* Connection Status */}
        <div className="mt-8 bg-white rounded-lg shadow-sm border border-slate-200 p-6">
          <h3 className="text-lg font-semibold text-slate-900 mb-4">Status połączenia</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="flex items-center">
              <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span className="text-sm text-slate-600">Frontend (React)</span>
            </div>
            <div className="flex items-center">
              <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
              <span className="text-sm text-slate-600">Backend (Node.js)</span>
            </div>
            <div className="flex items-center">
              <div className={`w-3 h-3 rounded-full mr-2 ${users.length > 0 ? 'bg-green-500' : 'bg-yellow-500'}`}></div>
              <span className="text-sm text-slate-600">Backend Extended (Java)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
