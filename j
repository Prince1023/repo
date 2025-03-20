///////  Arrange MapMarks  //////////



#include <bits/stdc++.h>
using namespace std;

// A structure to store an individual sheet (an M×M block)
struct Sheet {
    int id;
    vector<string> grid;  // each sheet’s grid (M rows, each of length M)
    string top, bottom, left, right; // its four borders
};

// Global variables
int N, M;            // full map size and sheet size
int K;               // number of sheets per side: K = N/M
vector<Sheet> sheets;

// We need to know which sheet (by our “cut” order) contains S and which contains D
int sheetS = -1, sheetD = -1;
int s_r_local, s_c_local, d_r_local, d_c_local;

// isTrack returns true if the cell is either a track ('T') or one of the stops 'S' or 'D'
inline bool isTrack(char ch){
    return (ch=='T' || ch=='S' || ch=='D');
}

// Global variables for backtracking the arrangement:
int bestAnswer = INT_MAX;
vector<bool> used; // used[i]==true if sheet i has been assigned already
vector<vector<int>> placement; // placement[r][c] is the sheet index put at that grid position

// When two sheets are adjacent (say, one is to the left) we require that for every row in the touching border,
// the cell from the left sheet’s right–edge and the candidate sheet’s left–edge share the “track” property.
bool checkCompatibility(int r, int c, int candidate) {
    Sheet &cand = sheets[candidate];
    if(c > 0) {
        int leftSheet = placement[r][c-1];
        Sheet &L = sheets[leftSheet];
        for (int i = 0; i < M; i++){
            bool leftVal = isTrack(L.right[i]);
            bool rightVal = isTrack(cand.left[i]);
            if(leftVal != rightVal)
                return false;
        }
    }
    if(r > 0) {
        int topSheet = placement[r-1][c];
        Sheet &T = sheets[topSheet];
        for (int j = 0; j < M; j++){
            bool topVal = isTrack(T.bottom[j]);
            bool botVal = isTrack(cand.top[j]);
            if(topVal != botVal)
                return false;
        }
    }
    return true;
}

// After a full placement is determined, we “assemble” the overall map and use BFS to compute the distance (if any)
// from S to D. (We allow moves up/down/left/right only if the cell is either a track (‘T’) or one of the stops.)
int computeBFS(){
    int totalSize = K * M;
    vector<string> fullMap(totalSize, string(totalSize, ' '));
    for (int i = 0; i < K; i++){
        for (int j = 0; j < K; j++){
            int sheetIndex = placement[i][j];
            Sheet &sh = sheets[sheetIndex];
            for (int r = 0; r < M; r++){
                for (int c = 0; c < M; c++){
                    fullMap[i*M + r][j*M + c] = sh.grid[r][c];
                }
            }
        }
    }
    // S is known to lie in the top–left sheet (at relative position (s_r_local, s_c_local))
    // and D in the bottom–right sheet (with relative position (d_r_local, d_c_local)).
    int startR = 0*M + s_r_local;
    int startC = 0*M + s_c_local;
    int endR = (K-1)*M + d_r_local;
    int endC = (K-1)*M + d_c_local;

    vector<vector<int>> dist(totalSize, vector<int>(totalSize, -1));
    queue<pair<int,int>> q;
    dist[startR][startC] = 1;
    q.push({startR, startC});
    int dr[4] = {1,-1,0,0}, dc[4] = {0,0,1,-1};

    while(!q.empty()){
        auto cur = q.front(); q.pop();
        int r = cur.first, c = cur.second;
        if(r==endR && c==endC)
            return dist[r][c];
        for (int k = 0; k < 4; k++){
            int nr = r+dr[k], nc = c+dc[k];
            if(nr<0 || nr>=totalSize || nc<0 || nc>=totalSize) continue;
            if(dist[nr][nc] != -1) continue;
            if(isTrack(fullMap[nr][nc])){
                dist[nr][nc] = dist[r][c] + 1;
                q.push({nr, nc});
            }
        }
    }
    return INT_MAX; // unreachable – no valid track path
}

// DFS that assigns sheets into the K×K grid in row–major order.
// (The top–left and bottom–right positions are “fixed” to sheetS and sheetD respectively.)
void dfs(int idx) {
    if(idx == K*K){
        int d = computeBFS();
        bestAnswer = min(bestAnswer, d);
        return;
    }
    int r = idx / K;
    int c = idx % K;
    // Fixed placements:
    if(r==0 && c==0) {
        if(used[sheetS]) return;
        placement[r][c] = sheetS;
        used[sheetS] = true;
        dfs(idx+1);
        used[sheetS] = false;
        return;
    }
    if(r==K-1 && c==K-1) {
        if(used[sheetD]) return;
        placement[r][c] = sheetD;
        used[sheetD] = true;
        if(checkCompatibility(r,c,sheetD))
            dfs(idx+1);
        used[sheetD] = false;
        return;
    }
    // For free positions, try every sheet not already used – but do NOT allow S or D here.
    for (int i = 0; i < (int)sheets.size(); i++){
        if(used[i]) continue;
        if(i==sheetS || i==sheetD) continue;
        if(!checkCompatibility(r,c,i)) continue;
        used[i] = true;
        placement[r][c] = i;
        dfs(idx+1);
        used[i] = false;
    }
}

// Main – read input, “cut” the map into sheets, identify S and D (and their local coordinates),
// then backtrack over arrangements, and finally print the minimum BFS distance.

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    cin >> N >> M;
    vector<string> fullMap(N);
    for (int i = 0; i < N; i++){
        cin >> fullMap[i];
    }
    // We assume N is divisible by M.
    K = N / M;

    // Cut the full map into K*K sheets.
    for (int i = 0; i < K; i++){
        for (int j = 0; j < K; j++){
            Sheet sh;
            sh.id = i*K+j;
            for (int r = 0; r < M; r++){
                string rowSegment = fullMap[i*M + r].substr(j*M, M);
                sh.grid.push_back(rowSegment);
            }
            // compute borders:
            sh.top = sh.grid[0];
            sh.bottom = sh.grid[M-1];
            string leftB = "", rightB = "";
            for (int r = 0; r < M; r++){
                leftB.push_back(sh.grid[r][0]);
                rightB.push_back(sh.grid[r][M-1]);
            }
            sh.left = leftB;
            sh.right = rightB;

            sheets.push_back(sh);
        }
    }

    // Identify which sheet contains S and D.
    bool foundS = false, foundD = false;
    for (int i = 0; i < (int)sheets.size(); i++){
        for (int r = 0; r < M; r++){
            for (int c = 0; c < M; c++){
                if(sheets[i].grid[r][c]=='S'){
                    sheetS = i;
                    s_r_local = r;
                    s_c_local = c;
                    foundS = true;
                }
                if(sheets[i].grid[r][c]=='D'){
                    sheetD = i;
                    d_r_local = r;
                    d_c_local = c;
                    foundD = true;
                }
            }
        }
    }
    if(!foundS || !foundD){
        // if input problem – should not occur.
        cout << -1 << "\n";
        return 0;
    }

    // Setup global variables for DFS. (The total number of sheets equals K*K.)
    used.assign(sheets.size(), false);
    placement.assign(K, vector<int>(K, -1));

    // The DFS will force the S–sheet into top–left and the D–sheet into bottom–right.
    dfs(0);

    cout << bestAnswer << "\n";
    return 0;
}
