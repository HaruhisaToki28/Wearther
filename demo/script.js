// 画面切り替え機能
document.addEventListener('DOMContentLoaded', function() {
    const screens = document.querySelectorAll('.screen');
    const tabItems = document.querySelectorAll('.tab-item');
    
    // タブバーのクリックイベント
    tabItems.forEach((tab, index) => {
        tab.addEventListener('click', function() {
            // すべての画面を非表示
            screens.forEach(screen => screen.classList.remove('active'));
            
            // すべてのタブを非アクティブ
            tabItems.forEach(item => item.classList.remove('active'));
            
            // クリックされたタブをアクティブに
            this.classList.add('active');
            
            // 対応する画面を表示
            switch(index) {
                case 0:
                    document.getElementById('home-screen').classList.add('active');
                    break;
                case 1:
                    document.getElementById('timeline-screen').classList.add('active');
                    break;
                case 2:
                    // AI提案画面（未実装）
                    document.getElementById('home-screen').classList.add('active');
                    break;
                case 3:
                    document.getElementById('profile-screen').classList.add('active');
                    break;
            }
        });
    });
    
    // ストーリーアイテムのクリックイベント（デモ用）
    const storyItems = document.querySelectorAll('.story-item');
    storyItems.forEach(item => {
        item.addEventListener('click', function() {
            storyItems.forEach(s => s.classList.remove('active'));
            this.classList.add('active');
        });
    });
    
    // フィルタータブのクリックイベント
    const filterTabs = document.querySelectorAll('.filter-tab');
    filterTabs.forEach(tab => {
        tab.addEventListener('click', function() {
            filterTabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
        });
    });
    
    // 期間タブのクリックイベント
    const periodTabs = document.querySelectorAll('.period-tab');
    periodTabs.forEach(tab => {
        tab.addEventListener('click', function() {
            periodTabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
        });
    });
    
    // プロフィールタブのクリックイベント
    const profileTabs = document.querySelectorAll('.profile-tab');
    profileTabs.forEach(tab => {
        tab.addEventListener('click', function() {
            profileTabs.forEach(t => t.classList.remove('active'));
            this.classList.add('active');
        });
    });
});

