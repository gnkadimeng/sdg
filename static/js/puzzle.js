
        let tiles = [];
        let emptyIndex = 8;
        let moveCount = 0;
        let timer = 0;
        let timerInterval;
        let gameStarted = false;

        const pieceClasses = [
            'piece1', 'piece2', 'piece3', 'piece4', 
            'piece5', 'piece6', 'piece7', 'piece8'
        ];

        const tileBackgroundPositions = [
            '5px 5px',    // Top-left
            '-137px 5px', // Top-middle
            '-279px 5px', // Top-right
            '5px -137px', // Middle-left
            '-137px -137px', // Center
            '-279px -137px', // Middle-right
            '5px -279px', // Bottom-left
            '-137px -279px'  // Bottom-middle
        ];

        function createTiles() {
            const puzzleGrid = document.getElementById('puzzleGrid');
            puzzleGrid.innerHTML = '';
            tiles = [];
            
            for (let i = 0; i < 9; i++) {
                if (i < 8) {
                    const tile = document.createElement('div');
                    tile.className = `tile ${pieceClasses[i]}`;
                    tile.textContent = `${i + 1}`;
                    tile.dataset.index = i;
                    tile.dataset.originalIndex = i;
                    tile.addEventListener('click', moveTile);
                    
                    tile.style.backgroundImage = `url("{{ url_for('static', filename='img/uj.png') }}")`;
                    tile.style.backgroundPosition = tileBackgroundPositions[i];
                    tile.style.backgroundRepeat = 'no-repeat';
                    
                    tiles.push(tile);
                } else {
                    const emptyTile = document.createElement('div');
                    emptyTile.className = 'tile empty';
                    emptyTile.dataset.index = i;
                    tiles.push(emptyTile);
                }
            }
            
            tiles.forEach((tile, index) => {
                const row = Math.floor(index / 3);
                const col = index % 3;
                tile.style.left = `${col * 143 + 5}px`;
                tile.style.top = `${row * 143 + 5}px`;
                tile.dataset.index = index;
                puzzleGrid.appendChild(tile);
            });
        }

        function moveTile(e) {
            if (!gameStarted) {
                startTimer();
                gameStarted = true;
            }

            const clickedIndex = parseInt(e.target.dataset.index);
            const row = Math.floor(clickedIndex / 3);
            const col = clickedIndex % 3;
            const emptyRow = Math.floor(emptyIndex / 3);
            const emptyCol = emptyIndex % 3;

            if ((Math.abs(row - emptyRow) === 1 && col === emptyCol) ||
                (Math.abs(col - emptyCol) === 1 && row === emptyRow)) {
                
                e.target.classList.add('connecting');
                setTimeout(() => e.target.classList.remove('connecting'), 300);
                
                e.target.classList.add('celebrate');
                setTimeout(() => e.target.classList.remove('celebrate'), 800);
                
                [tiles[clickedIndex], tiles[emptyIndex]] = [tiles[emptyIndex], tiles[clickedIndex]];
                
                tiles.forEach((tile, index) => {
                    const newRow = Math.floor(index / 3);
                    const newCol = index % 3;
                    tile.style.left = `${newCol * 143 + 5}px`;
                    tile.style.top = `${newRow * 143 + 5}px`;
                    tile.dataset.index = index;
                });

                emptyIndex = clickedIndex;
                moveCount++;
                document.getElementById('moveCount').textContent = moveCount;
                
                checkWin();
            }
        }

        function checkWin() {
            const isSolved = tiles.every((tile, index) => {
                if (tile.className.includes('empty')) {
                    return index === 8;
                }
                return parseInt(tile.dataset.originalIndex) === index;
            });
            
            if (isSolved) {
                clearInterval(timerInterval);
                document.getElementById('winMessage').style.display = 'block';
                gameStarted = false;
                
                tiles.forEach((tile, index) => {
                    if (!tile.className.includes('empty')) {
                        setTimeout(() => {
                            tile.classList.add('celebrate');
                            tile.classList.add('connecting');
                            setTimeout(() => {
                                tile.classList.remove('celebrate');
                                tile.classList.remove('connecting');
                            }, 800);
                        }, index * 150);
                    }
                });
            }
        }

        function shuffleTiles() {
            clearInterval(timerInterval);
            moveCount = 0;
            timer = 0;
            gameStarted = false;
            document.getElementById('moveCount').textContent = '0';
            document.getElementById('timer').textContent = '0';
            document.getElementById('winMessage').style.display = 'none';

            const difficulty = document.getElementById('difficulty').value;
            let shuffleCount = 300;
            
            switch(difficulty) {
                case 'easy': shuffleCount = 100; break;
                case 'medium': shuffleCount = 300; break;
                case 'hard': shuffleCount = 500; break;
            }

            for (let i = 0; i < shuffleCount; i++) {
                const validMoves = [];
                const emptyRow = Math.floor(emptyIndex / 3);
                const emptyCol = emptyIndex % 3;

                if (emptyRow > 0) validMoves.push(emptyIndex - 3);
                if (emptyRow < 2) validMoves.push(emptyIndex + 3);
                if (emptyCol > 0) validMoves.push(emptyIndex - 1);
                if (emptyCol < 2) validMoves.push(emptyIndex + 1);

                const randomMove = validMoves[Math.floor(Math.random() * validMoves.length)];
                [tiles[emptyIndex], tiles[randomMove]] = [tiles[randomMove], tiles[emptyIndex]];
                emptyIndex = randomMove;
            }

            tiles.forEach((tile, index) => {
                const row = Math.floor(index / 3);
                const col = index % 3;
                tile.style.left = `${col * 143 + 5}px`;
                tile.style.top = `${row * 143 + 5}px`;
                tile.dataset.index = index;
            });
        }

        function startTimer() {
            timerInterval = setInterval(() => {
                timer++;
                document.getElementById('timer').textContent = timer;
            }, 1000);
        }

        function showSolution() {
            document.getElementById('solvedOverlay').style.display = 'block';
        }

        function hideSolution() {
            document.getElementById('solvedOverlay').style.display = 'none';
        }

        createTiles();
        shuffleTiles();
 