const API_URL = 'http://localhost:8080';

function getRecommendations() {
    console.log('🔘 Button clicked!');
    
    const checkboxes = document.querySelectorAll('input[name="accessibility"]:checked');
    const selectedNeeds = Array.from(checkboxes).map(cb => cb.value);
    
    console.log('📋 Selected needs:', selectedNeeds);
    
    if (selectedNeeds.length === 0) {
        alert('Please select at least one accessibility need!');
        return;
    }
    
    const resultsDiv = document.getElementById('results');
    resultsDiv.style.display = 'block';
    resultsDiv.innerHTML = '<div class="loading">🔍 Searching for accessible places...</div>';
    
    fetch(`${API_URL}/api/recommendations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ needs: selectedNeeds })
    })
    .then(response => {
        console.log('📡 Response status:', response.status);
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        return response.json();
    })
    .then(data => {
        console.log('✅ API Response:', data);
        displayResults(data, selectedNeeds);
    })
    .catch(error => {
        console.error('❌ Error:', error);
        resultsDiv.innerHTML = `
            <div class="error-message">
                <h3>⚠️ Connection Error</h3>
                <p>Could not connect to the backend server.</p>
                <p>Error: ${error.message}</p>
            </div>
        `;
    });
}

function displayResults(data, selectedNeeds) {
    console.log('📊 Displaying', data.count, 'results');
    
    const resultsDiv = document.getElementById('results');
    
    if (!data.success || data.recommendations.length === 0) {
        resultsDiv.innerHTML = `
            <div class="no-results">
                <h2>😔 No matching places found</h2>
                <p>We couldn't find places matching your needs.</p>
                <p style="font-size: 0.9em; color: #999; margin-top: 1rem;">
                    Selected: ${selectedNeeds.join(', ')}
                </p>
            </div>
        `;
        return;
    }
    
    let html = `
        <h2 class="results-header">✨ Found ${data.count} Accessible Places</h2>
        <p style="text-align: center; color: #666; margin-bottom: 2rem;">
            Showing places matching: <strong>${selectedNeeds.map(formatTag).join(', ')}</strong>
        </p>
        <div class="results-grid">
    `;
    
    data.recommendations.forEach(place => {
        html += `
            <div class="place-card">
                <h3 class="place-name">${place.name}</h3>
                <div class="place-match-info">
                    <span class="match-badge">✓ ${place.matches} of ${selectedNeeds.length} matches</span>
                </div>
                <div class="place-tags">
                    ${place.tags.map(tag => {
                        const isMatched = selectedNeeds.includes(tag);
                        const emoji = getTagEmoji(tag);
                        return `<span class="tag ${isMatched ? 'matched' : ''}">${emoji} ${formatTag(tag)}</span>`;
                    }).join('')}
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    resultsDiv.innerHTML = html;
    resultsDiv.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function getTagEmoji(tag) {
    const emojiMap = {
        'wheelchair-friendly': '♿',
        'minimal-walking': '👣',
        'shaded': '🌳',
        'quiet-space': '🤫',
        'braille-paths': '👆',
        'step-free-access': '🚪',
        'accessible-restrooms': '🚻',
        'handrails': '🤝'
    };
    return emojiMap[tag] || '📍';
}

function formatTag(tag) {
    return tag
        .split('-')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
}

window.addEventListener('DOMContentLoaded', function() {
    console.log('🌐 Page loaded, connecting button...');
    
    const button = document.querySelector('.accessibility-button');
    
    if (button) {
        button.onclick = getRecommendations;
        console.log('✅ Button connected successfully!');
    } else {
        console.error('❌ Button not found!');
    }
    
    testConnection();
});

async function testConnection() {
    try {
        const response = await fetch(`${API_URL}/api/test`);
        const data = await response.json();
        console.log('✅ Backend connection successful:', data);
    } catch (error) {
        console.warn('⚠️ Backend not available:', error.message);
    }
}